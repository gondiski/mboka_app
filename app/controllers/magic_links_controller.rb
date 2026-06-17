# frozen_string_literal: true

class MagicLinksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def new
    authorize :magic_link, :new?
  end

  def create
    authorize :magic_link, :create?
    user = User.find_by(email: params[:email]&.strip&.downcase)

    if user.nil?
      redirect_to new_user_session_path, alert: "No account found with that email. Please sign up first."
    elsif user.status == "active" || user.status == "pending"
      token = user.generate_magic_link!
      UserMailer.magic_link(user, token).deliver_later
      Rails.logger.info "Magic link sent to #{user.email}"
      redirect_to check_email_path, notice: "Authentication link dispatched to your inbox."
    else
      redirect_to new_user_session_path, alert: "Account is #{user.status}. Contact support."
    end
  end

  def validate
    authorize :magic_link, :validate?
    token_hash = Devise.token_generator.digest(User, :magic_link_token, params[:token])
    user = User.find_by(magic_link_token: token_hash)

    if user && user.magic_link_expires_at > Time.current
      user.update!(magic_link_token: nil, magic_link_expires_at: nil, status: "active")
      sign_in(user)
      redirect_to profile_path, notice: "Session established successfully."
    else
      redirect_to new_user_session_path, alert: "Authentication token expired or invalid."
    end
  end

  def check_email
    authorize :magic_link, :check_email?
  end
end
