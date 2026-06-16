# frozen_string_literal: true

class IntelligenceGatheringJob
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: 3

  def perform(week_of)
    week_date = Date.parse(week_of)
    topics = Topic.joins(:user_topics).distinct

    topics.find_each do |topic|
      existing = TopicDigest.find_by(topic: topic, week_of: week_date)
      next if existing.present?

      digest_content = AiAgentService.call(
        topics: [topic.name],
        designation: "general"
      )

      TopicDigest.create!(
        topic: topic,
        content: digest_content,
        week_of: week_date
      )
    end

    DigestDeliveryJob.perform_async(week_of)
  end
end
