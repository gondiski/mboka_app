# frozen_string_literal: true

class DigestSchedulerJob
  include Sidekiq::Job

  sidekiq_options queue: :critical

  def perform
    schedule = DigestSchedule.active_schedule
    return unless schedule
    return unless schedule.should_send_today?(Date.current)

    now = Time.current
    send_time = schedule.send_time

    return unless now.hour == send_time.hour && now.min == send_time.min

    week_of = Date.current.beginning_of_week.to_s
    IntelligenceGatheringJob.perform_async(week_of)
  end
end
