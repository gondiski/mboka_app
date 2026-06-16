# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @token = token
    @login_url = validate_magic_link_url(token: token)

    mail(
      to: @user.email,
      subject: "Your Mboka Access Link"
    )
  end

  def topic_digest(user, topic_digests)
    @user = user
    @topic_digests = topic_digests

    mail(
      to: @user.email,
      subject: "Your Weekly Intelligence Digest - #{Date.current.strftime('%B %d, %Y')}"
    )
  end

  def account_setup_invitation(user, token)
    @user = user
    @token = token
    @login_url = validate_magic_link_url(token: token)

    mail(
      to: @user.email,
      subject: "Welcome to Mboka - Complete Your Setup"
    )
  end
end
