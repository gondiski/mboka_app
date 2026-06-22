# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_authorized, raise: false

  def about; end
  def privacy; end
  def terms; end
  def locked; end

  def health
    settings = AdminSetting.first
    render json: {
      status: "ok",
      trial_start: settings&.trial_start_at,
      trial_active: settings&.trial_active?,
      app_accessible: settings&.app_accessible?,
      date: Date.current
    }
  end
end
