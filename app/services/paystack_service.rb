# frozen_string_literal: true

require "net/http"
require "json"

class PaystackService
  BASE_URL = "https://api.paystack.co"

  def self.initialize_transaction(email:, amount_cents:, reference:, metadata: {})
    new.initialize_transaction(email: email, amount_cents: amount_cents, reference: reference, metadata: metadata)
  end

  def self.verify_transaction(reference)
    new.verify_transaction(reference)
  end

  def initialize_transaction(email:, amount_cents:, reference:, metadata: {})
    secret_key = paystack_secret_key
    raise "Paystack secret key not configured" if secret_key.blank?

    uri = URI("#{BASE_URL}/transaction/initialize")
    body = {
      email: email,
      amount: amount_cents,
      reference: reference,
      metadata: metadata,
      callback_url: metadata[:callback_url]
    }.compact

    post(uri, body, secret_key)
  end

  def verify_transaction(reference)
    secret_key = paystack_secret_key
    raise "Paystack secret key not configured" if secret_key.blank?

    uri = URI("#{BASE_URL}/transaction/verify/#{reference}")
    get(uri, secret_key)
  end

  private

  def paystack_secret_key
    AdminSetting.first&.paystack_secret_key.presence ||
      Rails.application.credentials.dig(:paystack, :secret_key)
  end

  def post(uri, body, secret_key)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{secret_key}"
    request["Content-Type"] = "application/json"
    request.body = body.to_json

    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  end

  def get(uri, secret_key)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{secret_key}"

    response = http.request(request)
    JSON.parse(response.body, symbolize_names: true)
  end
end
