# frozen_string_literal: true

class Admin::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?, policy_class: Admin::DashboardPolicy
    @total_users  = User.count
    @total_topics = Topic.count
    @sent_count    = Ahoy::Message.count
    @opened_count  = Ahoy::Message.where.not(opened_at: nil).count
    @clicked_count = Ahoy::Click.count
    @open_rate = @sent_count > 0 ? (@opened_count.to_f / @sent_count * 100).round(1) : 0

    @common_topics = Topic.joins(:user_topics)
                          .group("topics.name")
                          .order("count(user_topics.id) DESC")
                          .limit(5)
                          .count

    # Paginated digest stats
    @current_week_digests = TopicDigest.current_week.includes(:topic)
    @digest_stats = build_digest_stats
    @pagy_digests, @digest_page = pagy_array(@digest_stats, items: 5)

    # Chart data
    @weekly_open_data = weekly_open_rates
    @monthly_open_data = monthly_open_rates
    @topic_open_data = topic_open_rates
    @digest_performance_data = digest_performance_over_time
  end

  private

  def build_digest_stats
    return [] if @current_week_digests.empty?

    messages_by_topic = Ahoy::Message.where(mailer: "UserMailer#topic_digest")
                                       .where(sent_at: 1.week.ago..)
                                       .group(:user_id)
                                       .pluck(:user_id)
                                       .uniq

    @current_week_digests.map do |digest|
      users_with_topic = digest.topic.users.where(id: messages_by_topic).count
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: 1.week.ago..).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: 1.week.ago..).where.not(opened_at: nil).count

      {
        topic_name: digest.topic.name,
        users_reached: users_with_topic,
        generated_at: digest.created_at,
        open_rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
      }
    end
  end

  def weekly_open_rates
    data = {}
    11.downto(0) do |i|
      date = i.days.ago.to_date
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date.beginning_of_day..date.end_of_day).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date.beginning_of_day..date.end_of_day).where.not(opened_at: nil).count
      data[date.strftime("%a %b %d")] = { sent: sent, opened: opened, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data
  end

  def monthly_open_rates
    data = {}
    11.downto(0) do |i|
      date = i.months.ago
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date.beginning_of_month..date.end_of_month).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date.beginning_of_month..date.end_of_month).where.not(opened_at: nil).count
      data[date.strftime("%b %Y")] = { sent: sent, opened: opened, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data
  end

  def topic_open_rates
    data = {}
    Topic.all.each do |topic|
      user_ids = topic.user_ids
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids).where.not(opened_at: nil).count
      data[topic.name] = { sent: sent, opened: opened, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data.sort_by { |_, v| -v[:rate] }.to_h
  end

  def digest_performance_over_time
    data = []
    9.downto(0) do |i|
      week_start = i.weeks.ago.beginning_of_week
      week_end = i.weeks.ago.end_of_week
      digests = TopicDigest.where(week_of: week_start.beginning_of_day..week_end.end_of_day)
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: week_start..week_end).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: week_start..week_end).where.not(opened_at: nil).count
      data << {
        week: week_start.strftime("%b %d"),
        digests_count: digests.count,
        sent: sent,
        opened: opened,
        rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
      }
    end
    data
  end
end
