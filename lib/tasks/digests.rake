# frozen_string_literal: true

namespace :digests do
  desc "Show status of all digest cron jobs in Sidekiq"
  task status: :environment do
    require "sidekiq/cron"

    puts "=== Digest Cron Jobs ==="
    jobs = Sidekiq::Cron::Job.all
    if jobs.empty?
      puts "  ❌ No cron jobs registered!"
    else
      jobs.each do |j|
        puts "  ✅ #{j.name} → #{j.klass} | cron: #{j.cron} | status: #{j.status}"
      end
    end

    puts ""
    puts "=== Digest Schedule ==="
    schedule = DigestSchedule.where(active: true).last
    if schedule
      puts "  active: #{schedule.active?}"
      puts "  days: #{schedule.days.inspect}"
      puts "  send_time: #{schedule.send_time&.strftime('%H:%M')} UTC"
      puts "  generation_day: #{schedule.generation_day} (#{schedule.generation_day_name})"
      puts "  delivery cron: #{schedule.cron_expression}"
      puts "  generation cron: #{schedule.generation_cron_expression}"
    else
      puts "  ❌ No active schedule found!"
    end

    puts ""
    puts "=== Unsent Digests ==="
    puts "  Total unsent approved: #{TopicDigest.unsent.count}"
    TopicDigest.group(:status).count.each { |k, v| puts "  #{k}: #{v}" }
  end

  desc "Register digest cron jobs in Sidekiq (run after deploy)"
  task setup_cron: :environment do
    require "sidekiq/cron"

    schedule = DigestSchedule.where(active: true).last
    unless schedule
      puts "❌ No active DigestSchedule found. Create one in the admin panel first."
      exit 1
    end

    # Clean up all old jobs
    %w[digest-delivery digest-generation digest-scheduler].each do |name|
      existing = Sidekiq::Cron::Job.find(name)
      if existing
        existing.destroy
        puts "🗑  Removed old cron job: #{name}"
      end
    rescue StandardError
      # ignore
    end

    # Create delivery cron
    if schedule.cron_expression.present?
      result = Sidekiq::Cron::Job.create(
        name: "digest-delivery",
        cron: schedule.cron_expression,
        class: "DigestDeliveryJob"
      )
      puts "✅ Created digest-delivery → DigestDeliveryJob | cron: #{schedule.cron_expression}"
    else
      puts "⚠️  No delivery cron expression (check schedule days and send_time)"
    end

    # Create generation cron
    if schedule.generation_cron_expression.present?
      result = Sidekiq::Cron::Job.create(
        name: "digest-generation",
        cron: schedule.generation_cron_expression,
        class: "IntelligenceGatheringJob"
      )
      puts "✅ Created digest-generation → IntelligenceGatheringJob | cron: #{schedule.generation_cron_expression}"
    else
      puts "⚠️  No generation cron expression (check schedule settings)"
    end

    puts ""
    puts "Done! Verify with: rake digests:status"
  end
end
