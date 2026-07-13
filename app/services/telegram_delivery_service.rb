# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

class TelegramDeliveryService
  def self.send_message(chat_id, text)
    token = ENV["TELEGRAM_BOT_TOKEN"]
    return false if token.blank?

    uri = URI.parse("https://api.telegram.org/bot#{token}/sendMessage")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump({
      "chat_id" => chat_id,
      "text" => text,
      "parse_mode" => "Markdown"
    })

    req_options = { use_ssl: uri.scheme == "https" }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      Rails.logger.info("Telegram message sent successfully to #{chat_id}")
      true
    else
      Rails.logger.error("Failed to send Telegram message to #{chat_id}: #{response.body}")
      false
    end
  end

  def self.deliver_digest(user, digests)
    return false if user.telegram_chat_id.blank?

    # Compile digests into a single Markdown message
    message = "📬 *Your Weekly Mboka Opportunity Radar*\n\n"

    digests.each do |digest|
      message += "🔥 *#{digest.topic.name}*\n"
      
      # Show only the Key Insights section (before the jobs block)
      insights = digest.content.split('<!-- JOBS_SECTION -->').first

      # Convert basic HTML from AI into simple Markdown
      insights = insights.gsub(/<h2>(.*?)<\/h2>/, "*\\1*\n")
      insights = insights.gsub(/<p>(.*?)<\/p>/, "\\1\n\n")
      insights = insights.gsub(/<strong>(.*?)<\/strong>/, "*\\1*")
      insights = insights.gsub(/<br\s*\/?>/, "\n")
      
      # Strip any remaining tags
      insights = ActionController::Base.helpers.strip_tags(insights)

      message += "#{insights}\n"

      # Add link to full digest with jobs
      digest_url = Rails.application.routes.url_helpers.topic_digest_url(digest, host: Rails.application.routes.default_url_options[:host] || "localhost:3000")
      message += "💼 [See More Jobs →](#{digest_url})\n\n"
    end

    send_message(user.telegram_chat_id, message)
  end
end
