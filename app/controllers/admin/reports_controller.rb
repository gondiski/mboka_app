# frozen_string_literal: true

class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :report, :show?, policy_class: Admin::ReportPolicy

    @topics = Topic.all.order(:name)
    @selected_topic = params[:topic_id].present? ? Topic.find_by(id: params[:topic_id]) : nil
    @date_from = params[:from].present? ? Date.parse(params[:from]) : 12.weeks.ago.to_date
    @date_to = params[:to].present? ? Date.parse(params[:to]) : Date.current

    @topic_open_data = topic_open_rates_for_range(@date_from, @date_to)
    @weekly_trend_data = weekly_trend_for_range(@date_from, @date_to)
    @user_growth_data = user_growth_for_range(@date_from, @date_to)
    @top_topics_by_subscribers = top_topics_by_subscribers
    @digest_send_stats = digest_send_stats_for_range(@date_from, @date_to)
  end

  private

  def topic_open_rates_for_range(from, to)
    topics = @selected_topic ? [@selected_topic] : Topic.all
    data = {}
    topics.each do |topic|
      user_ids = topic.user_ids
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids, sent_at: from..to.end_of_day).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids, sent_at: from..to.end_of_day).where.not(opened_at: nil).count
      clicked = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids, sent_at: from..to.end_of_day).where.not(clicked_at: nil).count
      data[topic.name] = { sent: sent, opened: opened, clicked: clicked, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data.sort_by { |_, v| -v[:rate] }.to_h
  end

  def weekly_trend_for_range(from, to)
    data = []
    date = from.beginning_of_week
    while date <= to
      week_end = date.end_of_week
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date..week_end.end_of_day).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date..week_end.end_of_day).where.not(opened_at: nil).count
      clicked = Ahoy::Message.where(mailer: "UserMailer#topic_digest", sent_at: date..week_end.end_of_day).where.not(clicked_at: nil).count
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
      data << {
        month: date.strftime("%b %Y"),
        total: total,
        active: active
      }
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
    data = {}
    Topic.all.each do |topic|
      user_ids = topic.user_ids
      sent = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids, sent_at: from..to.end_of_day).count
      opened = Ahoy::Message.where(mailer: "UserMailer#topic_digest", user_type: "User", user_id: user_ids, sent_at: from..to.end_of_day).where.not(opened_at: nil).count
      data[topic.name] = { sent: sent, opened: opened, rate: sent > 0 ? (opened.to_f / sent * 100).round(1) : 0 }
    end
    data.sort_by { |_, v| -v[:sent] }.to_h
  end
end
