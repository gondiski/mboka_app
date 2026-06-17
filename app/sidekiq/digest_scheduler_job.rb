# frozen_string_literal: true

class DigestSchedulerJob
  include Sidekiq::Job

  sidekiq_options queue: :critical

  def perform
    schedule = DigestSchedule.active_schedule
    return unless schedule

    today = Date.current

    if schedule.should_generate_today?(today)
      week_of = today.beginning_of_week.to_s
      IntelligenceGatheringJob.perform_async(week_of)
    end

    if schedule.should_send_today?(today)
      week_of = today.beginning_of_week.to_s
      DigestDeliveryJob.perform_async(week_of)
    end
  end
end
