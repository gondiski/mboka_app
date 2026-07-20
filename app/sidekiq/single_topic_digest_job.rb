# frozen_string_literal: true

class SingleTopicDigestJob
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: 2

  def perform(topic_id, week_of = nil)
    week_date = week_of ? Date.parse(week_of) : Date.current.beginning_of_week
    topic = Topic.find_by(id: topic_id)
    return unless topic

    existing = TopicDigest.find_by(topic: topic, week_of: week_date)
    return if existing.present?

    jobs = JobSearchService.call(topic_name: topic.name, schedule_date: week_date)

    rss_topics = [
      "Education, Training & Academia",
      "Science, Research & Innovation",
      "International Development & Humanitarian Work",
      "Community Development, Youth & Inclusion",
      "Government, Public Policy & Diplomacy",
      "Entrepreneurship, Startups & Innovation"
    ]

    if rss_topics.include?(topic.name) || topic.name.match?(/scholarship|grant|fellowship|sponsorship/i)
      jobs += RssOpportunityService.fetch
    end

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
      status: :approved
    )

    Rails.logger.info("SingleTopicDigestJob: Created digest for #{topic.name}")
  rescue StandardError => e
    Rails.logger.error("SingleTopicDigestJob: Failed for topic #{topic_id}: #{e.class} - #{e.message}")
    raise # Re-raise so Sidekiq retries
  end
end
