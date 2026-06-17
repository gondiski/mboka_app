# frozen_string_literal: true

puts "Seeding production admin and moderator users..."

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
topics.each { |name| Topic.find_or_create_by!(name: name) }
puts "Ensured #{Topic.count} topics exist."

admins_data = [
  { full_name: "Eugene", email: "eugene@dnrstudios.co.ke", designation: "Platform Admin" },
  { full_name: "Enoch", email: "enoch@thoth.africa", designation: "Platform Admin" },
  { full_name: "Digital", email: "digital@dnrstudios.co.ke", designation: "Platform Admin" }
]

admins_data.each do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.full_name = attrs[:full_name]
    u.designation = attrs[:designation]
    u.status = "active"
    u.password = "password123"
    u.password_confirmation = "password123"
  end
  user.add_role(:admin) unless user.has_role?(:admin)
  puts "Admin: #{user.email}"
end

moderators_data = [
  { full_name: "David Kiirya", email: "david.kiirya@dnrstudios.co.ke", designation: "Community Manager" }
]

moderators_data.each do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.full_name = attrs[:full_name]
    u.designation = attrs[:designation]
    u.status = "active"
    u.password = "password123"
    u.password_confirmation = "password123"
  end
  user.add_role(:moderator) unless user.has_role?(:moderator)
  DesignationTopicMatcher.assign_to_user(user)
  puts "Moderator: #{user.email}"
end

puts ""
puts "=== Summary ==="
puts "Admins:     #{User.joins(:roles).where(roles: { name: 'admin' }).count}"
puts "Moderators: #{User.joins(:roles).where(roles: { name: 'moderator' }).count}"
puts ""
puts "=== Credentials ==="
puts "eugene@dnrstudios.co.ke / password123"
puts "enoch@thoth.africa / password123"
puts "digital@dnrstudios.co.ke / password123"
puts "david.kiirya@dnrstudios.co.ke / password123"
