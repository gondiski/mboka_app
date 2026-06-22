# frozen_string_literal: true

class Admin::SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @settings = AdminSetting.instance
    authorize @settings, :show?, policy_class: Admin::SettingsPolicy
  end

  def update
    @settings = AdminSetting.instance
    authorize @settings, :update?, policy_class: Admin::SettingsPolicy

    if @settings.update(settings_params)
      redirect_to admin_settings_path, notice: "API settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:admin_setting).permit(
      :serpapi_key,
      :anthropic_api_key,
      :total_price_cents,
      :installment_count
    )
  end
end
