# app/controllers/magic_links_controller.rb
class MagicLinksController < ApplicationController
  def new
    authorize MagicLink
  end

  def create
    authorize MagicLink
    user = User.find_by(email: params[:email].strip.downcase)
    if user && %w[active pending].include?(user.status)
      token = user.generate_magic_link!
      UserMailer.magic_link(user, token).deliver_later
      redirect_to root_path, notice: "Authentication link dispatched to your inbox."
    else
      redirect_to new_magic_link_path, alert: "Account unavailable or disabled."
    end
  end

  def validate
    authorize MagicLink
    token_hash = Devise.token_generator.digest(User, :magic_link_token, params[:token])
    user = User.find_by(magic_link_token: token_hash)

    if user && user.magic_link_expires_at > Time.current
      user.update!(magic_link_token: nil, magic_link_expires_at: nil, status: "active")
      sign_in(user)
      redirect_to profile_path, notice: "Session established successfully."
    else
      redirect_to new_magic_link_path, alert: "Authentication token expired or corrupt."
    end
  end

  def check_email
    authorize MagicLink
  end
end
