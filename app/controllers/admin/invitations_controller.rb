# frozen_string_literal: true

class Admin::InvitationsController < ApplicationController
  before_action :authenticate_user!

  def create
    authorize User, :import?, policy_class: Admin::UserPolicy

    email = params[:email]&.strip&.downcase
    full_name = params[:full_name]&.strip
    designation = params[:designation]&.strip
    role = params[:role].presence_in(%w[admin moderator subscriber]) || "subscriber"

    if email.blank?
      redirect_to admin_users_path, alert: "Email is required."
      return
    end

    existing_user = User.find_by(email: email)

    if existing_user
      if existing_user.invited? && existing_user.invitation_accepted_at.nil?
        existing_user.invite!
        redirect_to admin_users_path, notice: "Invitation resent to #{email}."
      else
        redirect_to admin_users_path, alert: "#{email} already has an account."
      end
      return
    end

    user = User.invite!(
      email: email,
      full_name: full_name.presence || email.split("@").first,
      designation: designation.presence || "Invited User",
      status: "pending",
      invited_by: current_user
    )

    user.add_role(role) unless user.has_role?(role.to_sym)

    redirect_to admin_users_path, notice: "Invitation sent to #{email} with role: #{role}."
  end
end
