# frozen_string_literal: true

class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :report, :show?, policy_class: Admin::ReportPolicy

    @topics = Topic.all.order(:name)
    @selected_topic = params[:topic_id].present? ? Topic.find_by(id: params[:topic_id]) : nil
    @date_from = params[:from].present? ? Date.parse(params[:from]) : 12.weeks.ago.to_date
    @date_to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    cache_key = "reports/#{@selected_topic&.id}/#{@date_from}/#{@date_to}"

    cached = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      {
        topic_open_data: topic_open_rates_for_range(@date_from, @date_to),
        weekly_trend_data: weekly_trend_for_range(@date_from, @date_to),
        user_growth_data: user_growth_for_range(@date_from, @date_to),
        top_topics_by_subscribers: top_topics_by_subscribers,
        digest_send_stats: digest_send_stats_for_range(@date_from, @date_to)
      }
    end

    @topic_open_data = cached[:topic_open_data]
    @weekly_trend_data = cached[:weekly_trend_data]
    @user_growth_data = cached[:user_growth_data]
    @top_topics_by_subscribers = cached[:top_topics_by_subscribers]
    @digest_send_stats = cached[:digest_send_stats]
  end

  private

  def topic_open_rates_for_range(from, to)
    topics = @selected_topic ? [@selected_topic] : Topic.all
    data = {}

    # Single query for all messages in range
    messages = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: from..to.end_of_day)
    messages_by_user = messages.group_by(&:user_id)

    topics.each do |topic|
      user_ids = UserTopic.where(topic_id: topic.id).pluck(:user_id)
      topic_messages = user_ids.flat_map { |uid| messages_by_user[uid] || [] }
      sent = topic_messages.size
      opened = topic_messages.count { |m| m.opened_at.present? }
      clicked = topic_messages.count { |m| m.clicked_at.present? }
      data[topic.name] = { sent: sent, opened: opened, clicked: clicked, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data.sort_by { |_, v| -v[:rate] }.to_h
  end

  def weekly_trend_for_range(from, to)
    messages = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: from..to.end_of_day)
    messages_by_week = messages.group_by { |m| m.sent_at.beginning_of_week.to_date }

    data = []
    date = from.beginning_of_week
    while date <= to
      week_messages = messages_by_week[date] || []
      sent = week_messages.size
      opened = week_messages.count { |m| m.opened_at.present? }
      clicked = week_messages.count { |m| m.clicked_at.present? }
      data << {
        week: date.strftime("%b %d"),
        sent: sent,
        opened: opened,
        clicked: clicked,
        rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0
      }
      date += 1.week
    end
    data
  end

  def user_growth_for_range(from, to)
    data = []
    date = from.beginning_of_month
    while date <= to
      month_end = date.end_of_month
      total = User.where(created_at: ..month_end.end_of_day).count
      active = User.where(status: "active", created_at: ..month_end.end_of_day).count
      data << { month: date.strftime("%b %Y"), total: total, active: active }
      date += 1.month
    end
    data
  end

  def top_topics_by_subscribers
    Topic.joins(:user_topics)
         .group("topics.name")
         .order("count(user_topics.id) DESC")
         .limit(15)
         .count
  end

  def digest_send_stats_for_range(from, to)
    messages = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: from..to.end_of_day)
    messages_by_user = messages.group_by(&:user_id)

    data = {}
    Topic.find_each do |topic|
      user_ids = UserTopic.where(topic_id: topic.id).pluck(:user_id)
      topic_messages = user_ids.flat_map { |uid| messages_by_user[uid] || [] }
      sent = topic_messages.size
      opened = topic_messages.count { |m| m.opened_at.present? }
      data[topic.name] = { sent: sent, opened: opened, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data.sort_by { |_, v| -v[:sent] }.to_h
  end
end
