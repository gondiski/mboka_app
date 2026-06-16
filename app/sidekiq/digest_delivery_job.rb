# frozen_string_literal: true

class DigestDeliveryJob
  include Sidekiq::Job

  sidekiq_options queue: :mailers, retry: 3

  def perform(week_of)
    week_date = Date.parse(week_of)
    users = User.where(status: "active").joins(:topics).distinct

    users.find_each do |user|
      user_digests = TopicDigest.for_week(week_date).for_topics(user.topic_ids)

      next if user_digests.empty?

      UserMailer.topic_digest(user, user_digests).deliver_now
    end
  end
end
