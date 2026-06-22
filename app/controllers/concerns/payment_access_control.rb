# frozen_string_literal: true

module PaymentAccessControl
  extend ActiveSupport::Concern

  included do
    before_action :check_app_access
  end

  private

  def check_app_access
    return if app_access_allowed?

    redirect_to locked_path, status: :see_other
  end

  def app_access_allowed?
    settings = AdminSetting.first

    # No settings or no trial started yet - allow everything
    return true if settings.nil?
    return true if settings.trial_start_at.blank?

    # Trial active or all payments complete - allow everything
    return true if settings.app_accessible?

    # Trial expired and no payment - only allow locked page and payment flows
    accessible_without_payment?
  end

  def accessible_without_payment?
    allowed_paths = %w[
      pages
      subscribers
      profiles
      magic_links
      email_preferences
      devise
      webhooks
    ]

    return true if allowed_paths.any? { |path| controller_path.start_with?(path) }
    return true if controller_path.start_with?("admin/payments")
    return true if controller_path.start_with?("admin/settings")
    return true if controller_name == "locked"

    false
  end
end
