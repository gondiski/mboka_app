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
    destroy_cron_job("digest-delivery")
    destroy_cron_job("digest-generation")

    return unless schedule.active?

    # Create delivery cron job
    if schedule.cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-delivery",
        cron: schedule.cron_expression,
        class: "DigestDeliveryJob",
        args: [Date.current.beginning_of_week.to_s]
      )
    end

    # Create generation cron job
    if schedule.generation_cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-generation",
        cron: schedule.generation_cron_expression,
        class: "IntelligenceGatheringJob",
        args: [Date.current.beginning_of_week.to_s]
      )
    end
  end

  def destroy_cron_job(name)
    existing = Sidekiq::Cron::Job.find(name)
    existing&.destroy
  rescue StandardError => e
    Rails.logger.warn("Failed to destroy cron job '#{name}': #{e.message}")
  end
end
