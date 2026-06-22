# frozen_string_literal: true

class DigestDeliveryJob
  include Sidekiq::Job

  sidekiq_options queue: :mailers, retry: 3

  def perform(week_of)
    week_date = Date.parse(week_of)

    # Users with topics get their subscribed digests
    users_with_topics = User.where(status: "active", subscribed: true)
                            .joins(:topics).distinct

    users_with_topics.find_each do |user|
      user_digests = TopicDigest.for_week(week_date)
                                .for_topics(user.topic_ids)
                                .ready_to_send

      next if user_digests.empty?

      shuffled_digests = user_digests.to_a.shuffle
      UserMailer.topic_digest(user, shuffled_digests).deliver_later
    end

    # Users without topics get a random digest as they wait to choose topics
    users_without_topics = User.where(status: "active", subscribed: true)
                               .left_joins(:user_topics)
                               .where(user_topics: { id: nil })

    all_ready_digests = TopicDigest.for_week(week_date).ready_to_send.to_a

    return if all_ready_digests.empty?

    users_without_topics.find_each do |user|
      random_digest = all_ready_digests.sample
      UserMailer.topic_digest(user, [random_digest]).deliver_later
    end

    clear_analytics_cache
  end

  private

  def clear_analytics_cache
    Rails.cache.delete("dashboard_stats")
    Rails.cache.delete_matched("reports/*")
    Rails.cache.delete_matched("weekly_open_rates")
    Rails.cache.delete_matched("monthly_open_rates")
    Rails.cache.delete_matched("topic_open_rates")
    Rails.cache.delete_matched("digest_performance")
  rescue StandardError => e
    Rails.logger.warn("Failed to clear analytics cache: #{e.message}")
  end
end
