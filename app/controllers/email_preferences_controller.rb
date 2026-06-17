# frozen_string_literal: true

class EmailPreferencesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_authorized, raise: false

  layout "application"

  def show
    @user = User.find_by(unsubscribe_token: params[:token])

    if @user.nil?
      render :invalid_token, status: :not_found
      return
    end

    @topics = Topic.all.order(:name)
    @subscribed_topic_ids = @user.topic_ids
  end

  def update
    @user = User.find_by(unsubscribe_token: params[:token])

    if @user.nil?
      render :invalid_token, status: :not_found
      return
    end

    subscribed = params[:subscribed] == "true"
    topic_ids = params[:topic_ids]&.map(&:to_i) || []

    if subscribed
      @user.resubscribe_to_emails!
      # Sync topic subscriptions
      current_ids = @user.topic_ids
      (@user.user_topics.where.not(topic_id: topic_ids)).destroy_all
      topic_ids.each do |tid|
        @user.user_topics.find_or_create_by!(topic_id: tid)
      end
    else
      @user.unsubscribe_from_emails!
    end

    redirect_to email_preferences_path(token: params[:token]),
                notice: subscribed ? "Email preferences updated." : "You've been unsubscribed from all emails."
  end

  def unsubscribe
    @user = User.find_by(unsubscribe_token: params[:token])

    if @user.nil?
      render :invalid_token, status: :not_found
      return
    end

    @user.unsubscribe_from_emails!
    render :unsubscribed
  end
end
