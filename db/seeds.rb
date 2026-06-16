# frozen_string_literal: true

topics = [
  "Software Engineering",
  "Data Science & AI",
  "Product Design",
  "Product Management",
  "DevOps & Cloud",
  "Cybersecurity",
  "Mobile Development",
  "Frontend Development",
  "Backend Development",
  "Full Stack Development",
  "NGO & Non-Profit Grants",
  "Government Grants",
  "Research Fellowships",
  "Academic Scholarships",
  "Startup Accelerators",
  "Startup Incubators",
  "Venture Capital & Funding",
  "Angel Investor Programs",
  "Remote Jobs",
  "Tech Jobs Kenya",
  "Fintech Opportunities",
  "Healthtech Opportunities",
  "Edtech Opportunities",
  "Agritech Opportunities",
  "Climate & Sustainability",
  "Social Enterprise",
  "Digital Marketing",
  "Blockchain & Web3",
  "Embedded Systems & IoT",
  "Business & Entrepreneurship"
]

topics.each do |name|
  Topic.find_or_create_by!(name: name)
end

puts "Seeded #{Topic.count} topics."

# Admin user
admin = User.find_or_initialize_by(email: "admin@thoth.africa")
admin.assign_attributes(
  full_name: "Admin",
  designation: "Platform Admin",
  status: "active",
  password: "password123",
  password_confirmation: "password123"
)
admin.save!
admin.add_role(:admin) unless admin.has_role?(:admin)

puts "Admin user: #{admin.email} (password: password123)"
