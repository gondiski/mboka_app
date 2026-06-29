namespace :telegram do
  desc "Set the Telegram Webhook"
  task set_webhook: :environment do
    token = ENV["TELEGRAM_BOT_TOKEN"]
    domain = ENV["APP_DOMAIN"] || "https://mboka.dnrstudios.co.ke"

    if token.blank?
      puts "❌ TELEGRAM_BOT_TOKEN is not set in .env"
      exit
    end

    webhook_url = "#{domain}/webhooks/telegram/#{token}"

    uri = URI.parse("https://api.telegram.org/bot#{token}/setWebhook")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = JSON.dump({ "url" => webhook_url })

    req_options = { use_ssl: uri.scheme == "https" }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      puts "✅ Webhook successfully set to: #{webhook_url}"
    else
      puts "❌ Failed to set webhook: #{response.body}"
    end
  end
end
