# frozen_string_literal: true

class Admin::PaymentsController < ApplicationController
  before_action :authenticate_user!

  def show
    @settings = AdminSetting.instance
    authorize @settings, :show?, policy_class: Admin::PaymentsPolicy

    @summary = @settings.payments_summary
    @payments = @settings.payments.order(created_at: :desc)
    @next_installment = @settings.next_installment
  end



  def history
    @settings = AdminSetting.instance
    authorize @settings, :history?, policy_class: Admin::PaymentsPolicy

    @payments = @settings.payments.order(created_at: :desc)
    @summary = @settings.payments_summary
  end
end
