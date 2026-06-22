# frozen_string_literal: true

namespace :mboka do
  desc "Seed production admin and moderator users"
  task seed_admins: :environment do
    unless Rails.env.production?
      puts "This task is for production only. Use `bin/rails db:seed` for development."
      next
    end

    puts "=== Seeding Production Admins ==="

    # Ensure topics exist
    topics = [
      "Software Engineering", "Data Science & AI", "Product Design", "Product Management",
      "DevOps & Cloud", "Cybersecurity", "Mobile Development", "Frontend Development",
      "Backend Development", "Full Stack Development", "NGO & Non-Profit Grants",
      "Government Grants", "Research Fellowships", "Academic Scholarships",
      "Startup Accelerators", "Startup Incubators", "Venture Capital & Funding",
      "Angel Investor Programs", "Remote Jobs", "Tech Jobs Kenya",
      "Fintech Opportunities", "Healthtech Opportunities", "Edtech Opportunities",
      "Agritech Opportunities", "Climate & Sustainability", "Social Enterprise",
      "Digital Marketing", "Blockchain & Web3", "Embedded Systems & IoT",
      "Business & Entrepreneurship"
    ]
    topics.each { |name| Topic.find_or_create_by!(name: name) }
    puts "Topics: #{Topic.count}"

    # Create admins
    admins = [
      { full_name: "Eugene", email: "eugene@dnrstudios.co.ke", designation: "Platform Admin" },
      { full_name: "Enoch", email: "enoch@thoth.africa", designation: "Platform Admin" },
      { full_name: "Digital", email: "digital@dnrstudios.co.ke", designation: "Platform Admin" }
    ]

    admins.each do |attrs|
      user = User.find_or_initialize_by(email: attrs[:email])
      user.assign_attributes(
        full_name: attrs[:full_name],
        designation: attrs[:designation],
        status: "active"
      )
      if user.new_record?
        user.password = "password123"
        user.password_confirmation = "password123"
      end
      user.save!
      user.add_role(:admin) unless user.has_role?(:admin)
      puts "  Admin: #{user.email} (#{user.status})"
    end

    # Create moderator
    moderator = User.find_or_initialize_by(email: "david.kiirya@dnrstudios.co.ke")
    moderator.assign_attributes(
      full_name: "David Kiirya",
      designation: "Community Manager",
      status: "active"
    )
    if moderator.new_record?
      moderator.password = "password123"
      moderator.password_confirmation = "password123"
    end
    moderator.save!
    moderator.add_role(:moderator) unless moderator.has_role?(:moderator)
    DesignationTopicMatcher.assign_to_user(moderator)
    puts "  Moderator: #{moderator.email} (#{moderator.status})"

    puts ""
    puts "=== Done ==="
    puts "Admins: #{User.joins(:roles).where(roles: { name: 'admin' }).count}"
    puts "Moderators: #{User.joins(:roles).where(roles: { name: 'moderator' }).count}"
  end

  desc "Set trial start date to July 1, 2026"
  task set_trial: :environment do
    settings = AdminSetting.instance
    settings.update!(trial_start_at: Date.new(2026, 7, 1).beginning_of_day)
    puts "Trial start date set to: #{settings.trial_start_at}"
    puts "Trial active: #{settings.trial_active?}"
    puts "Trial expires: July 31, 2026"
  end
end
