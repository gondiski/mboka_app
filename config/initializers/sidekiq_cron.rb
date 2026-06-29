# frozen_string_literal: true

require "sidekiq/cron"

# Bootstrap cron jobs from the saved DigestSchedule on server start.
# This ensures cron jobs survive Redis flushes and server restarts.
Rails.application.config.after_initialize do
  if defined?(Sidekiq::Cron::Job)
    schedule = DigestSchedule.where(active: true).last rescue nil
    next unless schedule

    # Clean up legacy scheduler job
    begin
      legacy = Sidekiq::Cron::Job.find("digest-scheduler")
      legacy&.destroy
      Rails.logger.info("Sidekiq Cron: Removed legacy digest-scheduler job")
    rescue StandardError
      # ignore
    end

    # Re-create delivery cron
    if schedule.cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-delivery",
        cron: schedule.cron_expression,
        class: "DigestDeliveryJob"
      )
      Rails.logger.info("Sidekiq Cron: Bootstrapped digest-delivery with cron '#{schedule.cron_expression}'")
    end

    # Re-create generation cron
    if schedule.generation_cron_expression.present?
      Sidekiq::Cron::Job.create(
        name: "digest-generation",
        cron: schedule.generation_cron_expression,
        class: "IntelligenceGatheringJob"
      )
      Rails.logger.info("Sidekiq Cron: Bootstrapped digest-generation with cron '#{schedule.generation_cron_expression}'")
    end
  end
end
