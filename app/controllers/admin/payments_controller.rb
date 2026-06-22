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

  def checkout
    @settings = AdminSetting.instance
    authorize @settings, :checkout?, policy_class: Admin::PaymentsPolicy

    unless @settings.paystack_configured?
      redirect_to admin_payments_path, alert: "Paystack is not configured. Please add PAYSTACK_SECRET_KEY to your .env file."
      return
    end

    installment_num = @settings.next_installment
    if installment_num.nil?
      redirect_to admin_payments_path, notice: "All installments have been paid."
      return
    end

    reference = "mboka-#{installment_num}-#{SecureRandom.hex(8)}"
    amount_cents = @settings.installment_amount_cents

    Rails.logger.info("[Paystack] Initializing payment: reference=#{reference}, amount=#{amount_cents}, email=#{current_user.email}")

    begin
      result = PaystackService.initialize_transaction(
        email: current_user.email,
        amount_cents: amount_cents,
        reference: reference,
        metadata: {
          installment_number: installment_num,
          admin_setting_id: @settings.id,
          callback_url: verify_admin_payments_url(reference: reference)
        }
      )

      Rails.logger.info("[Paystack] Response: #{result.inspect}")

      if result[:status] == true && result.dig(:data, :authorization_url).present?
        @payment = @settings.payments.create!(
          amount_cents: amount_cents,
          installment_number: installment_num,
          status: :pending,
          paystack_reference: reference
        )

        auth_url = result.dig(:data, :authorization_url)
        Rails.logger.info("[Paystack] Redirecting to: #{auth_url}")
        redirect_to auth_url, allow_other_host: true, status: :see_other
      else
        error_msg = result.dig(:message) || "Unknown error"
        Rails.logger.error("[Paystack] Failed: #{error_msg}")
        redirect_to admin_payments_path, alert: "Payment initialization failed: #{error_msg}"
      end
    rescue StandardError => e
      Rails.logger.error("[Paystack] Exception: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      redirect_to admin_payments_path, alert: "Payment error: #{e.message}"
    end
  end

  def verify
    @settings = AdminSetting.instance
    authorize @settings, :verify?, policy_class: Admin::PaymentsPolicy

    reference = params[:reference]
    payment = @settings.payments.find_by(paystack_reference: reference)

    if payment.nil?
      redirect_to admin_payments_path, alert: "Payment not found."
      return
    end

    begin
      result = PaystackService.verify_transaction(reference)

      if result[:status] == true && result.dig(:data, :status) == "success"
        payment.mark_success!(reference: reference)
        redirect_to admin_payments_path, notice: "Payment of $#{payment.amount_dollars} successful! App access extended for 30 days."
      else
        payment.mark_failed!(reference: reference)
        redirect_to admin_payments_path, alert: "Payment verification failed. Please contact support."
      end
    rescue StandardError => e
      Rails.logger.error("[Paystack] Verify error: #{e.message}")
      redirect_to admin_payments_path, alert: "Verification error: #{e.message}"
    end
  end

  def history
    @settings = AdminSetting.instance
    authorize @settings, :history?, policy_class: Admin::PaymentsPolicy

    @payments = @settings.payments.order(created_at: :desc)
    @summary = @settings.payments_summary
  end
end
