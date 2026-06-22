class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include PaymentAccessControl

  allow_browser versions: :modern

  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def after_sign_out_path_for(resource)
    root_path
  end

  private

  def pundit_user
    current_user
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
