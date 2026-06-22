# frozen_string_literal: true

module PaymentAccessControl
  extend ActiveSupport::Concern

  included do
    before_action :check_app_access
  end

  private

  def check_app_access
    return if app_access_allowed?

    # Add cache-busting headers to prevent Turbo from caching the redirect
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"

    redirect_to locked_path, status: :see_other
  end

  def app_access_allowed?
    return true if accessible_without_payment?

    settings = AdminSetting.first
    return true if settings.nil?

    settings.app_accessible?
  end

  def accessible_without_payment?
    allowed_paths = %w[
      pages
      subscribers
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
