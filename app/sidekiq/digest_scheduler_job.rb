# frozen_string_literal: true

class DigestSchedulerJob
  include Sidekiq::Job

  sidekiq_options queue: :critical

  def perform
    schedule = DigestSchedule.where(active: true).last
    return if schedule.nil?

    today = Date.current

    if schedule.should_generate_today?(today)
      IntelligenceGatheringJob.perform_async
    end

    if schedule.should_send_today?(today)
      DigestDeliveryJob.perform_async
    end
  end
end
