# frozen_string_literal: true

module PaymentAccessControl
  extend ActiveSupport::Concern

  included do
    before_action :check_app_access
  end

  private

  def check_app_access
    return if app_access_allowed?

    redirect_to locked_path
  end

  def app_access_allowed?
    return true if accessible_without_payment?

    settings = AdminSetting.first
    return true if settings.nil?

    # Always check fresh - no cache for access control
    settings.app_accessible?
  end

  def accessible_without_payment?
    allowed_paths = %w[
      pages
      magic_links
      email_preferences
      devise/sessions
      devise/registrations
      webhooks/paystack
    ]

    return true if allowed_paths.any? { |path| controller_path.start_with?(path) }
    return true if controller_path.start_with?("admin/payments")
    return true if controller_path.start_with?("admin/settings")
    return true if controller_name == "locked"

    false
  end
end
