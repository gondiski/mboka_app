# frozen_string_literal: true

class AdminSetting < ApplicationRecord
  validate :singleton_record, on: :create

  after_save :invalidate_api_key_cache

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
