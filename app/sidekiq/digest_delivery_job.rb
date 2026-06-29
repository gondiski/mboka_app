# frozen_string_literal: true

class DigestDeliveryJob
  include Sidekiq::Job

  sidekiq_options queue: :mailers, retry: 3

  def perform(week_of = nil)
    week_date = week_of ? Date.parse(week_of) : Date.current.beginning_of_week

    # Collect all unsent approved digests (current week + any backlog)
    current_week_unsent = TopicDigest.for_week(week_date).unsent
    backlog_unsent = TopicDigest.unsent.where.not(week_of: week_date.beginning_of_week)
    all_unsent = TopicDigest.unsent.to_a

    if all_unsent.empty?
      Rails.logger.info("DigestDeliveryJob: No unsent approved digests found. Skipping.")
      return
    end

    Rails.logger.info("DigestDeliveryJob: Found #{current_week_unsent.count} current week + #{backlog_unsent.count} backlog unsent digests")

    # Users with topics get their subscribed digests
    users_with_topics = User.where(status: "active", subscribed: true)
                            .joins(:topics).distinct

    users_with_topics.find_each do |user|
      user_digests = all_unsent.select { |d| user.topic_ids.include?(d.topic_id) }
      next if user_digests.empty?

      shuffled_digests = user_digests.shuffle

      deliver_to_user(user, shuffled_digests)
    end

    # Users without topics get a random digest
    users_without_topics = User.where(status: "active", subscribed: true)
                               .left_joins(:user_topics)
                               .where(user_topics: { id: nil })

    users_without_topics.find_each do |user|
      random_digest = all_unsent.sample
      deliver_to_user(user, [random_digest])
    end

    # Mark all unsent digests as sent
    all_unsent.each do |digest|
      digest.mark_sent!
    rescue StandardError => e
      Rails.logger.error("DigestDeliveryJob: Failed to mark digest #{digest.id} as sent: #{e.message}")
    end

    Rails.logger.info("DigestDeliveryJob: Delivery complete. #{all_unsent.size} digests marked as sent.")

    clear_analytics_cache
  end

  private

  def deliver_to_user(user, digests)
    preference = user.receive_via.to_s.downcase

    if preference.include?("telegram") && user.telegram_chat_id.present?
      TelegramDeliveryService.deliver_digest(user, digests)
    end

    if preference.include?("email") || preference.blank?
      UserMailer.topic_digest(user, digests).deliver_later
    end
  rescue StandardError => e
    Rails.logger.error("DigestDeliveryJob: Failed to deliver to user #{user.id} (#{user.email}): #{e.message}")
  end

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
