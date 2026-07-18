namespace :topics do
  desc "Consolidate granular topics into 26 broad categories"
  task consolidate: :environment do
    puts "Starting Topic Consolidation..."
    TopicConsolidationService.execute
    puts "✅ Done! Topics consolidated to #{Topic.count} categories."
  end
end
