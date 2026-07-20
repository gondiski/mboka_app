namespace :digests do
  desc "Resend this week's digests to users who have topics"
  task resend_this_week: :environment do
    puts "=" * 60
    puts "DIGEST DELIVERY — RESEND THIS WEEK"
    puts "=" * 60
    puts "Time: #{Time.current}"
    
    # Configure mailer for synchronous delivery
    ActionMailer::Base.delivery_method = :smtp
    if ENV["ZEPTOMAIL_API_KEY"].present?
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
    else
      puts "⚠️  WARNING: ZEPTOMAIL_API_KEY is not set. Using default mailer config."
    end
    ActionMailer::Base.default_url_options = { host: "mboka.dnrstudios.co.ke", protocol: "https" }
    Rails.application.routes.default_url_options = { host: "mboka.dnrstudios.co.ke", protocol: "https" }

    week_date = Date.current.beginning_of_week
    
    # Fetch digests for this week that are either approved or already sent
    digests = TopicDigest.where(week_of: week_date, status: ['approved', 'sent']).to_a
    puts "📬 Found #{digests.size} approved/sent digests for the week of #{week_date}"
    
    if digests.empty?
      puts "⚠️  No approved or sent digests found for this week."
      exit 0
    end
    
    # Only target users WITH topics
    users_with_topics = User.where(status: "active", subscribed: true).joins(:topics).distinct
    puts "👥 Users with topics: #{users_with_topics.count}"
    
    email_sent = 0
    email_failed = 0
    telegram_sent = 0
    telegram_failed = 0
    
    users_with_topics.find_each do |user|
      user_digests = digests.select { |d| user.topic_ids.include?(d.topic_id) }
      
      if user_digests.empty?
        # Use fallback if they have no matching digests
        shuffled = [digests.sample].compact
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
          puts "\n   ❌ Email failed for #{user.email}: #{e.message}"
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
          puts "\n   ❌ Telegram failed for #{user.full_name}: #{e.message}"
        end
      end

      print "." if (email_sent + telegram_sent) % 10 == 0
    end
    
    # Update status to sent if they were only approved
    digests.each do |digest|
      digest.mark_sent! if digest.approved?
    end

    puts "\n"
    puts "=" * 60
    puts "RESEND COMPLETE"
    puts "=" * 60
    puts "📧 Emails sent: #{email_sent} | failed: #{email_failed}"
    puts "📱 Telegram sent: #{telegram_sent} | failed: #{telegram_failed}"
    puts "=" * 60
  end
end
