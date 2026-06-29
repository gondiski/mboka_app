# frozen_string_literal: true

class Admin::DigestSchedulesController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = DigestSchedule.first_or_initialize
    authorize @schedule, :show?, policy_class: Admin::DigestSchedulePolicy
  end

  def update
    @schedule = DigestSchedule.first_or_initialize
    authorize @schedule, :update?, policy_class: Admin::DigestSchedulePolicy

    if @schedule.update(schedule_params)
      update_sidekiq_crons(@schedule)
      redirect_to admin_digest_schedule_path, notice: "Digest schedule updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    params.require(:digest_schedule).permit(:send_time, :active, :generation_day, days: []).tap do |p|
      p[:active] = ActiveModel::Type::Boolean.new.cast(p[:active]) if p.key?(:active)
    end
  end

  def update_sidekiq_crons(schedule)
    # Clean up all existing cron jobs (including legacy digest-scheduler)
    destroy_cron_job("digest-delivery")
    destroy_cron_job("digest-generation")
    destroy_cron_job("digest-scheduler") # legacy job that wrapped both

    return unless schedule.active?

    # Create delivery cron job — fires DigestDeliveryJob directly
    if schedule.cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-delivery",
        cron: schedule.cron_expression,
        class: "DigestDeliveryJob"
      )
      Rails.logger.info("Sidekiq Cron: Created digest-delivery with cron '#{schedule.cron_expression}'")
    end

    # Create generation cron job — fires IntelligenceGatheringJob directly
    if schedule.generation_cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-generation",
        cron: schedule.generation_cron_expression,
        class: "IntelligenceGatheringJob"
      )
      Rails.logger.info("Sidekiq Cron: Created digest-generation with cron '#{schedule.generation_cron_expression}'")
    end
  end

  def destroy_cron_job(name)
    existing = Sidekiq::Cron::Job.find(name)
    existing&.destroy
  rescue StandardError => e
    Rails.logger.warn("Failed to destroy cron job '#{name}': #{e.message}")
  end
end
