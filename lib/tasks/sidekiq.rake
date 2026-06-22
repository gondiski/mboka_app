# frozen_string_literal: true

namespace :sidekiq do
  desc "Clear all Sidekiq queues, retries, and dead jobs"
  task clear_all: :environment do
    require "sidekiq/api"

    puts "Clearing Sidekiq queues..."
    Sidekiq::Queue.all.each do |queue|
      count = queue.size
      queue.clear
      puts "  #{queue.name}: #{count} jobs cleared"
    end

    retry_set = Sidekiq::RetrySet.new
    puts "  Retries: #{retry_set.size} jobs cleared"
    retry_set.clear

    dead_set = Sidekiq::DeadSet.new
    puts "  Dead: #{dead_set.size} jobs cleared"
    dead_set.clear

    puts "Done!"
  end
end
