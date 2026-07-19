# frozen_string_literal: true

class IntelligenceGatheringJob
  include Sidekiq::Job

  sidekiq_options queue: :high, retry: 3

  def perform(week_of = nil)
    schedule = DigestSchedule.active_schedule

    if week_of
      week_date = Date.parse(week_of)
    elsif schedule
      # Determine the target week based on the NEXT delivery date
      next_delivery = Date.current
      (0..7).each do |i|
        date = Date.current + i.days
        if schedule.should_send_today?(date)
          next_delivery = date
          break
        end
      end
      week_date = next_delivery.beginning_of_week
    else
      week_date = Date.current.beginning_of_week
    end

    topics = Topic.all

    topics.each_with_index do |topic, index|
      existing = TopicDigest.find_by(topic: topic, week_of: week_date)
      next if existing.present?

      # Stagger the jobs by 1 minute each to avoid hitting Anthropic and SerpApi rate limits
      SingleTopicDigestJob.perform_in(index.minutes, topic.id, week_date.to_s)
    end
  end
end
