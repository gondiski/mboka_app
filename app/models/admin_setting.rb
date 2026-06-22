# frozen_string_literal: true

class AdminSetting < ApplicationRecord
  has_many :payments, dependent: :destroy

  validate :singleton_record, on: :create

  after_save :invalidate_api_key_cache

  TRIAL_DURATION = 30.days

  def self.instance
    first_or_create!
  end

  def serpapi_key_masked
    return "" if serpapi_key.blank?
    "#{serpapi_key[0..3]}#{"*" * [serpapi_key.length - 8, 4].max}#{serpapi_key[-4..]}"
  end

  def anthropic_api_key_masked
    return "" if anthropic_api_key.blank?
    "#{anthropic_api_key[0..3]}#{"*" * [anthropic_api_key.length - 8, 4].max}#{anthropic_api_key[-4..]}"
  end

  def paystack_configured?
    paystack_secret_key.present? && paystack_public_key.present? ||
      Rails.application.credentials.dig(:paystack, :secret_key).present? &&
      Rails.application.credentials.dig(:paystack, :public_key).present?
  end

  # --- Payment / Access Logic ---

  def total_price_dollars
    (total_price_cents || 200_000) / 100.0
  end

  def installment_amount_cents
    ((total_price_cents || 200_000) / (installment_count || 4).to_f).ceil
  end

  def installment_amount_dollars
    installment_amount_cents / 100.0
  end

  def start_trial!
    update!(trial_start_at: Time.current) if trial_start_at.blank?
  end

  def trial_active?
    return false if trial_start_at.blank?
    trial_start_at + TRIAL_DURATION > Time.current
  end

  def trial_expired?
    return false if trial_start_at.blank?
    !trial_active?
  end

  def current_payment
    payments.active.order(installment_number: :desc).first
  end

  def payment_active?
    current_payment.present?
  end

  def app_accessible?
    trial_active? || payment_active?
  end

  def next_installment
    last_paid = payments.completed.maximum(:installment_number) || 0
    return nil if last_paid >= (installment_count || 4)
    last_paid + 1
  end

  def all_payments_complete?
    paid_count = payments.completed.count
    paid_count >= (installment_count || 4)
  end

  def payments_summary
    total = installment_count || 4
    paid = payments.completed.count
    active = current_payment
    {
      total_installments: total,
      paid_installments: paid,
      remaining_installments: total - paid,
      current_expires_at: active&.expires_at,
      total_price: total_price_dollars,
      installment_amount: installment_amount_dollars
    }
  end

  private

  def singleton_record
    if AdminSetting.exists?
      errors.add(:base, "Only one admin settings record is allowed")
    end
  end

  def invalidate_api_key_cache
    if saved_change_to_attribute?(:serpapi_key)
      ApiKeyCache.invalidate("serpapi_key")
    end
    if saved_change_to_attribute?(:anthropic_api_key)
      ApiKeyCache.invalidate("anthropic_api_key")
    end
    Rails.cache.delete("admin_settings_access_check")
  rescue StandardError => e
    Rails.logger.warn("Failed to clear cache: #{e.message}")
  end
end
