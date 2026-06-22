# frozen_string_literal: true

class Webhooks::PaystackController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_authorized

  def receive
    payload = request.body.read
    signature = request.headers["X-Paystack-Signature"]

    unless valid_signature?(payload, signature)
      head :unauthorized
      return
    end

    event = JSON.parse(payload, symbolize_names: true)

    case event[:event]
    when "charge.success"
      handle_charge_success(event[:data])
    end

    head :ok
  end

  private

  def valid_signature?(payload, signature)
    secret = AdminSetting.first&.paystack_secret_key.presence ||
             Rails.application.credentials.dig(:paystack, :secret_key)
    return false if secret.blank?

    computed = OpenSSL::HMAC.hexdigest("SHA512", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(computed, signature.to_s)
  end

  def handle_charge_success(data)
    reference = data[:reference]
    return if reference.blank?

    payment = Payment.find_by(paystack_reference: reference)
    return if payment.nil? || payment.success?

    payment.mark_success!(reference: reference)
  end
end
