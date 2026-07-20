# One-off script to trigger digest delivery against the production database.
# Uses ZeptoMail for email and Telegram bot for messaging.
# Run with: RAILS_ENV=production DATABASE_URL="..." bin/rails runner lib/tasks/send_digests_now.rb
STDOUT.sync = true
# Run with: RAILS_ENV=production DATABASE_URL="..." bin/rails runner lib/tasks/send_digests_now.rb

puts "=" * 60
puts "DIGEST DELIVERY — MANUAL TRIGGER"
puts "=" * 60
puts "Time: #{Time.current}"
puts "Database: #{ActiveRecord::Base.connection.current_database}"
puts ""

# Force synchronous email delivery (no Sidekiq needed)
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  address: "smtp.zeptomail.com",
  port: 587,
  user_name: "emailapikey",
  password: ENV.fetch("ZEPTOMAIL_API_KEY"),
  authentication: :plain,
  enable_starttls_auto: true,
  open_timeout: 10,
  read_timeout: 10
}
ActionMailer::Base.default_url_options = { host: "mboka.dnrstudios.co.ke", protocol: "https" }
Rails.application.routes.default_url_options = { host: "mboka.dnrstudios.co.ke", protocol: "https" }

puts "✅ Mailer configured (ZeptoMail SMTP)"
puts "✅ Telegram bot token present: #{ENV['TELEGRAM_BOT_TOKEN'].present?}"
puts ""

# Find all unsent approved digests
all_unsent = TopicDigest.unsent.to_a
puts "📬 Unsent approved digests: #{all_unsent.size}"

if all_unsent.empty?
  puts "⚠️  Nothing to send! Approve some digests first."
  exit 0
end

all_unsent.each { |d| puts "   - #{d.topic.name} (week: #{d.week_of})" }
puts ""

# Users with topics
users_with_topics = User.where(status: "active", subscribed: true)
                        .joins(:topics).distinct
users_without_topics = User.where(status: "active", subscribed: true)
                           .left_joins(:user_topics)
                           .where(user_topics: { id: nil })

total_users = users_with_topics.count + users_without_topics.count
puts "👥 Users with topics: #{users_with_topics.count}"
puts "👥 Users without topics: #{users_without_topics.count}"
puts ""

email_sent = 0
email_failed = 0
telegram_sent = 0
telegram_failed = 0

# Deliver to users with topics
users_with_topics.find_each do |user|
  user_digests = all_unsent.select { |d| user.topic_ids.include?(d.topic_id) }
  if user_digests.empty?
    shuffled = [all_unsent.sample].compact
  else
    shuffled = user_digests.shuffle
  end

  next if shuffled.empty?
  preference = user.receive_via.to_s.downcase

  # Email delivery
  if preference.include?("email") || preference.blank?
    begin
      UserMailer.topic_digest(user, shuffled).deliver_now
      email_sent += 1
    rescue StandardError => e
      email_failed += 1
      puts "   ❌ Email failed for #{user.email}: #{e.message}"
    end
  end

  # Telegram delivery
  if preference.include?("telegram") && user.telegram_chat_id.present?
    begin
      result = TelegramDeliveryService.deliver_digest(user, shuffled)
      if result
        telegram_sent += 1
      else
        telegram_failed += 1
      end
    rescue StandardError => e
      telegram_failed += 1
      puts "   ❌ Telegram failed for #{user.full_name}: #{e.message}"
    end
  end

  print "." if (email_sent + telegram_sent) % 10 == 0
end

# Deliver to users without topics (random digest)
users_without_topics.find_each do |user|
  random_digest = all_unsent.sample
  preference = user.receive_via.to_s.downcase

  if preference.include?("email") || preference.blank?
    begin
      UserMailer.topic_digest(user, [random_digest]).deliver_now
      email_sent += 1
    rescue StandardError => e
      email_failed += 1
      puts "   ❌ Email failed for #{user.email}: #{e.message}"
    end
  end

  if preference.include?("telegram") && user.telegram_chat_id.present?
    begin
      result = TelegramDeliveryService.deliver_digest(user, [random_digest])
      if result
        telegram_sent += 1
      else
        telegram_failed += 1
      end
    rescue StandardError => e
      telegram_failed += 1
      puts "   ❌ Telegram failed for #{user.full_name}: #{e.message}"
    end
  end
end

puts ""
puts ""

# Mark digests as sent
all_unsent.each do |digest|
  digest.mark_sent!
rescue StandardError => e
  puts "   ❌ Failed to mark digest #{digest.id} as sent: #{e.message}"
end

puts "=" * 60
puts "DELIVERY COMPLETE"
puts "=" * 60
puts "📧 Emails sent: #{email_sent} | failed: #{email_failed}"
puts "📱 Telegram sent: #{telegram_sent} | failed: #{telegram_failed}"
puts "✅ Digests marked as sent: #{all_unsent.size}"
puts "=" * 60
