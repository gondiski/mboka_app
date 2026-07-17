# frozen_string_literal: true

class Admin::DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?, policy_class: Admin::DashboardPolicy

    stats = cached_dashboard_stats
    @total_users = stats[:total_users]
    @total_topics = stats[:total_topics]
    @sent_count = stats[:sent_count]
    @opened_count = stats[:opened_count]
    @clicked_count = stats[:clicked_count]
    @open_rate = stats[:open_rate]
    @digest_stats = stats[:digest_stats]
    @digest_page = stats[:digest_page]
    @weekly_open_data = stats[:weekly_open_data]
    @monthly_open_data = stats[:monthly_open_data]
    @topic_open_data = stats[:topic_open_data]
    @digest_performance_data = stats[:digest_performance_data]
  end

  private

  def cached_dashboard_stats
    Rails.cache.fetch("dashboard_stats", expires_in: 5.minutes) do
      {
        total_users: User.count,
        total_topics: Topic.count,
        sent_count: Ahoy::Message.count,
        opened_count: Ahoy::Message.where.not(opened_at: nil).count,
        clicked_count: Ahoy::Click.count,
        open_rate: calc_open_rate,
        digest_stats: build_digest_stats,
        digest_page: build_digest_stats.first(5),
        weekly_open_data: weekly_open_rates,
        monthly_open_data: monthly_open_rates,
        topic_open_data: topic_open_rates,
        digest_performance_data: digest_performance_over_time
      }
    end
  end

  def calc_open_rate
    sent = Ahoy::Message.count
    return 0 if sent == 0
    (Ahoy::Message.where.not(opened_at: nil).count.to_f / sent * 100).round(1)
  end

  def build_digest_stats
    @build_digest_stats ||= begin
      current_week_digests = TopicDigest.current_week.includes(:topic)
      return [] if current_week_digests.empty?

      topic_digest_msgs = Ahoy::Message.where(mailer: "UserMailer#topic_digest")
                                        .where(sent_at: 1.week.ago..)
      total_sent = topic_digest_msgs.count
      total_opened = topic_digest_msgs.where.not(opened_at: nil).count
      rate = total_sent > 0 ? (total_opened.to_f / total_sent * 100).round(1) : 0

      current_week_digests.map do |digest|
        {
          topic_name: digest.topic.name,
          users_reached: digest.topic.users.count,
          generated_at: digest.created_at,
          open_rate: rate
        }
      end.sort_by { |s| -s[:open_rate] }
    end
  end

  def weekly_open_rates
    Rails.cache.fetch("weekly_open_rates", expires_in: 1.hour) do
      data = {}
      messages = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: 12.days.ago..)
      messages_by_day = messages.group_by { |m| m.sent_at.to_date }

      11.downto(0) do |i|
        date = i.days.ago.to_date
        day_messages = messages_by_day[date] || []
        sent = day_messages.size
        opened = day_messages.count { |m| m.opened_at.present? }
        data[date.strftime("%a %b %d")] = {
          sent: sent,
          opened: opened,
          rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
        }
      end
      data
    end
  end

  def monthly_open_rates
    Rails.cache.fetch("monthly_open_rates", expires_in: 1.day) do
      data = {}
      11.downto(0) do |i|
        date = i.months.ago
        range = date.beginning_of_month..date.end_of_month
        sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: range).count
        opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: range).where.not(opened_at: nil).count
        data[date.strftime("%b %Y")] = {
          sent: sent,
          opened: opened,
          rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
        }
      end
      data
    end
  end

  def topic_open_rates
    Rails.cache.fetch("topic_open_rates", expires_in: 1.hour) do
      data = {}
      topics_with_counts = Topic.joins(:user_topics)
                                .group(:id)
                                .select("topics.id, topics.name, COUNT(user_topics.id) as subscriber_count")

      topics_with_counts.each do |topic|
        user_ids = UserTopic.where(topic_id: topic.id).pluck(:user_id)
        next if user_ids.empty?

        sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_id: user_ids).count
        opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_id: user_ids).where.not(opened_at: nil).count
        data[topic.name] = {
          sent: sent,
          opened: opened,
          rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
        }
      end
      data.sort_by { |_, v| -v[:rate] }.to_h
    end
  end

  def digest_performance_over_time
    Rails.cache.fetch("digest_performance", expires_in: 1.hour) do
      data = []
      9.downto(0) do |i|
        week_start = i.weeks.ago.beginning_of_week
        week_end = i.weeks.ago.end_of_week
        digests_count = TopicDigest.where(week_of: week_start.beginning_of_day..week_end.end_of_day).count
        sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: week_start..week_end).count
        opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: week_start..week_end).where.not(opened_at: nil).count
        data << {
          week: week_start.strftime("%b %d"),
          digests_count: digests_count,
          sent: sent,
          opened: opened,
          rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
        }
      end
      data
    end
  end
end
