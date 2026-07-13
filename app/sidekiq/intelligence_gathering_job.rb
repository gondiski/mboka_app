# frozen_string_literal: true

class IntelligenceGatheringJob
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: 3

  def perform(week_of = nil)
    week_date = week_of ? Date.parse(week_of) : Date.current.beginning_of_week
    topics = Topic.all

    topics.find_each do |topic|
      existing = TopicDigest.find_by(topic: topic, week_of: week_date)
      next if existing.present?

      begin
        jobs = JobSearchService.call(topic_name: topic.name, schedule_date: week_date)

        digest_content = AiAgentService.call(
          topics: [topic.name],
          designation: "general",
          jobs: jobs
        )

        TopicDigest.create!(
          topic: topic,
          content: digest_content,
          scraped_data: jobs.to_json,
          week_of: week_date,
          status: :draft
        )

        Rails.logger.info("IntelligenceGatheringJob: Created digest for #{topic.name}")
      rescue StandardError => e
        Rails.logger.error("IntelligenceGatheringJob: Failed for #{topic.name}: #{e.class} - #{e.message}")
        next
      end
    end
  end
end
