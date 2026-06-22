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

    settings = cached_admin_settings
    return true if settings.nil?
    return true if settings[:app_accessible]

    !(settings[:trial_expired] && !settings[:payment_active])
  end

  def cached_admin_settings
    Rails.cache.fetch("admin_settings_access_check", expires_in: 2.minutes) do
      settings = AdminSetting.first
      return nil if settings.nil?

      {
        trial_start_at: settings.trial_start_at,
        app_accessible: settings.app_accessible?,
        trial_expired: settings.trial_expired?,
        payment_active: settings.payment_active?
      }
    end
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
    return true if controller_name == "locked" && action_name == "locked"

    false
  end
end
