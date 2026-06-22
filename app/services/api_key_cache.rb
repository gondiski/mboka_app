# frozen_string_literal: true

class ApiKeyCache
  NAMESPACE = "api_keys"
  TTL = 24.hours

  KEYS = %w[serpapi_key anthropic_api_key].freeze

  def self.read(key_name)
    cache_key = "#{NAMESPACE}/#{key_name}"

    cached = Rails.cache.read(cache_key)
    return cached if cached.present?

    settings = AdminSetting.first
    return nil if settings.nil?

    value = settings.public_send(key_name)
    return nil if value.blank?

    Rails.cache.write(cache_key, value, expires_in: TTL)
    value
  end

  def self.write(key_name, value)
    cache_key = "#{NAMESPACE}/#{key_name}"

    if value.blank?
      Rails.cache.delete(cache_key)
    else
      Rails.cache.write(cache_key, value, expires_in: TTL)
    end
  end

  def self.invalidate(key_name)
    Rails.cache.delete("#{NAMESPACE}/#{key_name}")
  end

  def self.invalidate_all
    KEYS.each { |key| Rails.cache.delete("#{NAMESPACE}/#{key}") }
  end
end
