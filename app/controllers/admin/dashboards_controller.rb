# app/controllers/admin/dashboards_controller.rb
class Admin::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?, policy_class: Admin::DashboardPolicy
    @total_users  = User.count
    @total_topics = Topic.count
    @sent_count    = Ahoy::Message.count
    @opened_count  = Ahoy::Message.where.not(opened_at: nil).count
    @clicked_count = Ahoy::Click.count

    @common_topics = Topic.joins(:user_topics)
                          .group("topics.name")
                          .order("count(user_topics.id) DESC")
                          .limit(5)
                          .count

    @current_week_digests = TopicDigest.current_week.includes(:topic)
    @digest_stats = build_digest_stats
  end

  private

  def build_digest_stats
    return [] if @current_week_digests.empty?

    topic_ids = @current_week_digests.map(&:topic_id)

    messages_by_topic = Ahoy::Message.where(mailer: "UserMailer#topic_digest")
                                      .where(sent_at: 1.week.ago..)
                                      .group(:user_id)
                                      .pluck(:user_id)
                                      .uniq

    @current_week_digests.map do |digest|
      users_with_topic = digest.topic.users.where(id: messages_by_topic).count

      {
        topic_name: digest.topic.name,
        users_reached: users_with_topic,
        generated_at: digest.created_at
      }
    end
  end
end
