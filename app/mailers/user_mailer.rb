# frozen_string_literal: true

class UserMailer < ApplicationMailer
  helper :application

  def magic_link(user, token)
    @user = user
    @token = token
    @login_url = validate_magic_link_url(token: token)
    mail(to: @user.email, subject: "Your Mboka Access Link")
  end

  def topic_digest(user, topic_digests)
    @user = user
    @topic_digests = topic_digests
    @greeting = user.email_display_name
    @unsubscribe_token = user.unsubscribe_token
    @preferences_url = email_preferences_url(token: @unsubscribe_token)
    @unsubscribe_url = unsubscribe_email_url(token: @unsubscribe_token)

    mail(
      to: @user.email,
      subject: "Your Weekly Intelligence Digest - #{Date.current.strftime('%B %d, %Y')}"
    )
  end

  def account_setup_invitation(user, token)
    @user = user
    @token = token
    @login_url = validate_magic_link_url(token: token)
    mail(to: @user.email, subject: "Welcome to Mboka - Complete Your Setup")
  end

  def invitation_instructions(record, token, opts = {})
    @user = record
    @token = token
    @login_url = accept_user_invitation_url(invitation_token: token)
    mail(
      to: @user.email,
      subject: "You've Been Invited to Mboka"
    )
  end
end
