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

      jobs = JobSearchService.call(topic_name: topic.name, schedule_date: week_date)
      job_html = JobDigestFormatter.format(jobs)

      full_content = job_html.present? ? "#{digest_content}\n#{job_html}" : digest_content

      TopicDigest.create!(
        topic: topic,
        content: full_content,
        week_of: week_date,
        status: :draft
      )
    end
  end
end
