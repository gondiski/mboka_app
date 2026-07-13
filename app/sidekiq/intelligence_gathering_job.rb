# frozen_string_literal: true

class IntelligenceGatheringJob
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: 3

  def perform(week_of = nil)
    week_date = week_of ? Date.parse(week_of) : Date.current.beginning_of_week
    topics = Topic.all

    topics.each_with_index do |topic, index|
      existing = TopicDigest.find_by(topic: topic, week_of: week_date)
      next if existing.present?

      # Stagger the jobs by 1 minute each to avoid hitting Anthropic and SerpApi rate limits
      SingleTopicDigestJob.perform_in(index.minutes, topic.id, week_date.to_s)
    end
  end
end
