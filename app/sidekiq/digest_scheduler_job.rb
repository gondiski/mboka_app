# frozen_string_literal: true

class DigestSchedulerJob
  include Sidekiq::Job

  sidekiq_options queue: :critical

  def perform
    schedule = DigestSchedule.where(active: true).last
    return if schedule.nil?

    today = Date.current

    if schedule.respond_to?(:should_generate_today?) && schedule.should_generate_today?(today)
      week_of = today.beginning_of_week.to_s
      IntelligenceGatheringJob.perform_async(week_of)
    end

    if schedule.respond_to?(:should_send_today?) && schedule.should_send_today?(today)
      week_of = today.beginning_of_week.to_s
      DigestDeliveryJob.perform_async(week_of)
    end
  end
end
