# frozen_string_literal: true

puts "=== Mboka Production Seeds ==="
puts ""

# Topics (required for DesignationTopicMatcher)
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

topics.each do |name|
  Topic.find_or_create_by!(name: name)
rescue ActiveRecord::RecordInvalid => e
  puts "  Topic '#{name}' error: #{e.message}"
end
puts "Topics: #{Topic.count}"

# Admin users
admins_data = [
  { full_name: "Eugene", email: "eugene@dnrstudios.co.ke", designation: "Platform Admin" },
  { full_name: "Enoch", email: "enoch@thoth.africa", designation: "Platform Admin" },
  { full_name: "Digital", email: "digital@dnrstudios.co.ke", designation: "Platform Admin" }
]

admins_data.each do |attrs|
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
rescue ActiveRecord::RecordInvalid => e
  puts "  Admin '#{attrs[:email]}' error: #{e.message}"
end

# Moderator users
moderators_data = [
  { full_name: "David Kiirya", email: "david.kiirya@dnrstudios.co.ke", designation: "Community Manager" }
]

moderators_data.each do |attrs|
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
  user.add_role(:moderator) unless user.has_role?(:moderator)
  DesignationTopicMatcher.assign_to_user(user)
  puts "  Moderator: #{user.email} (#{user.status})"
rescue ActiveRecord::RecordInvalid => e
  puts "  Moderator '#{attrs[:email]}' error: #{e.message}"
end

puts ""
puts "=== Summary ==="
puts "Admins:     #{User.joins(:roles).where(roles: { name: 'admin' }).count}"
puts "Moderators: #{User.joins(:roles).where(roles: { name: 'moderator' }).count}"
puts "Topics:     #{Topic.count}"
puts ""
puts "=== Login Credentials ==="
puts "eugene@dnrstudios.co.ke / password123"
puts "enoch@thoth.africa / password123"
puts "digital@dnrstudios.co.ke / password123"
puts "david.kiirya@dnrstudios.co.ke / password123"
puts "========================="
