# frozen_string_literal: true

class Admin::DigestSchedulesController < ApplicationController
  before_action :authenticate_user!

  def show
    @schedule = DigestSchedule.first_or_initialize
    authorize @schedule, :show?
  end

  def update
    @schedule = DigestSchedule.first_or_initialize
    authorize @schedule, :update?

    if @schedule.update(schedule_params)
      update_sidekiq_cron(@schedule) if @schedule.active?
      redirect_to admin_digest_schedule_path, notice: "Digest schedule updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def schedule_params
    params.require(:digest_schedule).permit(:send_time, :active, days: [])
  end

  def update_sidekiq_cron(schedule)
    job_name = "digest-scheduler"

    existing = Sidekiq::Cron::Job.find(job_name)
    existing&.destroy

    return unless schedule.active?

    Sidekiq::Cron::Job.create(
      name: job_name,
      cron: schedule.cron_expression,
      class: "DigestSchedulerJob"
    )
  end
end
