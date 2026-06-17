# frozen_string_literal: true

puts "Clearing existing data..."
Favorite.destroy_all
TopicDigest.destroy_all
UserTopic.destroy_all
User.destroy_all
Topic.destroy_all

# Topics
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
puts "Created #{Topic.count} topics."

# Admin
admin = User.find_or_create_by!(email: "admin@thoth.africa") do |u|
  u.full_name = "Admin"
  u.designation = "Platform Admin"
  u.status = "active"
  u.password = "password123"
  u.password_confirmation = "password123"
end
admin.add_role(:admin) unless admin.has_role?(:admin)
puts "Admin: #{admin.email}"

# Moderators
moderators_data = [
  { full_name: "Faith Wanjiku", email: "faith@mboka.dnrstudios.co.ke", designation: "Community Manager" },
  { full_name: "Brian Ochieng", email: "brian@mboka.dnrstudios.co.ke", designation: "Program Coordinator" }
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

# Subscribers - 97 generated + 12 named = 109 total, trim to 100
designations = [
  "Senior Software Engineer", "Frontend Developer", "UX Designer", "Data Scientist",
  "NGO Program Manager", "Startup Founder", "Product Manager", "DevOps Engineer",
  "Digital Marketer", "Mobile Developer", "Research Fellow", "Fintech Analyst",
  "Backend Engineer", "Full Stack Developer", "Cloud Architect", "Security Analyst",
  "AI/ML Engineer", "Business Analyst", "Growth Hacker", "Technical Writer",
  "Venture Capital Associate", "Grant Writer", "Impact Investor", "Sustainability Consultant",
  "Blockchain Developer", "IoT Engineer", "Edtech Specialist", "Healthtech Consultant",
  "Agritech Innovator", "Social Entrepreneur"
]

first_names = %w[Amina Baraka Chidi Daniella Emmanuel Fatima Grace Hilda Ian Joy Kevin Liam Maria Nancy Oscar Peter Quincy Rachel Samuel Tanya Uma Victor Wendy Xavier Yara Zain]
last_names = %w[Kamau Otieno Mwangi Hassan Wanjiku Kiprop Njeri Odhiambo Wambui Mutua Akinyi Njoroge Ochieng Wafula Nyongesa Barasa Wekesa Simiyu Kibet Chebet Langat]

generated_users = []

# Named subscribers
named_subscribers = [
  { full_name: "Wanjiru Kamau", email: "wanjiru@example.com", designation: "Senior Software Engineer" },
  { full_name: "Peter Otieno", email: "peter@example.com", designation: "Frontend Developer" },
  { full_name: "Amina Hassan", email: "amina@example.com", designation: "UX Designer" },
  { full_name: "James Mwangi", email: "james@example.com", designation: "Data Scientist" },
  { full_name: "Sarah Ochieng", email: "sarah@example.com", designation: "NGO Program Manager" },
  { full_name: "David Kiprop", email: "david@example.com", designation: "Startup Founder" },
  { full_name: "Grace Njeri", email: "grace@example.com", designation: "Product Manager" },
  { full_name: "Samuel Odhiambo", email: "samuel@example.com", designation: "DevOps Engineer" },
  { full_name: "Lucy Wambui", email: "lucy@example.com", designation: "Digital Marketer" },
  { full_name: "Kevin Mutua", email: "kevin@example.com", designation: "Mobile Developer" },
  { full_name: "Esther Akinyi", email: "esther@example.com", designation: "Research Fellow" },
  { full_name: "Patrick Njoroge", email: "patrick@example.com", designation: "Fintech Analyst" }
]

# Generate remaining subscribers to reach 100 total
remaining_count = 100 - named_subscribers.length
remaining_count.times do |i|
  fname = first_names.sample
  lname = last_names.sample
  generated_users << {
    full_name: "#{fname} #{lname}",
    email: "#{fname.downcase}.#{lname.downcase}#{i + 1}@example.com",
    designation: designations.sample
  }
end

all_subscribers = named_subscribers + generated_users

all_subscribers.each do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.full_name = attrs[:full_name]
    u.designation = attrs[:designation]
    u.status = "active"
    u.password = "password123"
    u.password_confirmation = "password123"
  end
  user.add_role(:subscriber) unless user.has_role?(:subscriber)
  DesignationTopicMatcher.assign_to_user(user)
end

puts "Created #{User.count} users (#{User.joins(:roles).where(roles: { name: 'subscriber' }).count} subscribers)."

# Digest content templates
digest_templates = [
  {
    heading: "Top Opportunities This Week",
    items: [
      "<strong>Safaricom</strong> is hiring a Senior Backend Engineer (Nairobi) - KES 180K-250K.",
      "<strong>Andela</strong> launched a new Remote Senior Developer program for East Africa.",
      "<strong>Google</strong> announced the Africa Developer Scholarship 2026 - 1000 seats.",
      "<strong>Microsoft</strong> Africa has openings for Cloud Solutions Architects.",
      "<strong>Flutterwave</strong> is expanding engineering team in Lagos and Nairobi.",
      "<strong>Cellulant</strong> seeking Senior DevOps Engineer for payment infrastructure.",
      "<strong>Twiga Foods</strong> hiring Product Engineers for supply chain platform.",
      "<strong>M-Pesa</strong> looking for Mobile SDK Engineers.",
      "<strong>Jumia</strong> needs Senior Data Engineers for logistics optimization.",
      "<strong>Paystack</strong> hiring Backend Engineers for payment processing."
    ]
  },
  {
    heading: "Industry Insights",
    items: [
      "Rust and Go adoption in African startups increased by 40% this quarter.",
      "AI-assisted development tools reduced code review time by 35% at early adopters.",
      "Cloud-native architectures now used by 78% of Series A+ African startups.",
      "TypeScript adoption reached 92% among top African tech companies.",
      "Remote work policies now standard at 85% of African startups.",
      "GraphQL adoption grew 150% in the East African tech ecosystem.",
      "Container orchestration with Kubernetes became the default for new deployments.",
      "Serverless architectures reduced infrastructure costs by 45% for mid-stage startups.",
      "Microservices migration projects increased 60% among established fintechs.",
      "DevOps maturity model adoption doubled across African engineering teams."
    ]
  },
  {
    heading: "Funding & Grants",
    items: [
      "<strong>Hivos East Africa</strong> - Social Innovation Grant up to $50,000.",
      "<strong>Ford Foundation</strong> - Gender Justice Fund accepting proposals.",
      "<strong>USAID Kenya</strong> - Community Resilience Program RFP released.",
      "<strong>Google for Startups Africa</strong> - $100K equity-free funding available.",
      "<strong>Founders Factory Africa</strong> - 6-month program with $50K investment.",
      "<strong>Antler East Africa</strong> - Pre-seed program for first-time founders.",
      "<strong>Novastar Ventures</strong> - Series A Impact Fund actively investing.",
      "<strong>Acumen</strong> - East Africa Fellowship applications open.",
      "<strong>Village Capital</strong> - Climate Tech program accepting applications.",
      "<strong>TCAP</strong> - Tech Capacity Building Grant for NGOs ($25K-$100K)."
    ]
  },
  {
    heading: "Career Growth",
    items: [
      "Build a dedicated workspace. Time-zone overlap with your team is crucial.",
      "Focus on measurable impact. Funders want clear metrics and sustainable outcomes.",
      "AI product managers are the fastest growing role in tech this year.",
      "Product-led growth continues to dominate African SaaS companies.",
      "Short-form video dominates social media marketing strategies.",
      "Privacy-first marketing strategies are now essential for compliance.",
      "Leadership skills are the top predictor of career advancement in tech.",
      "Cross-functional collaboration experience valued 3x more than technical depth.",
      "Open source contributions remain the strongest portfolio signal for remote roles.",
      "Continuous learning budgets now average $3,000/year at top African tech companies."
    ]
  }
]

# Create 300 digests across 30 topics × 10 weeks
puts "\nCreating 300 digests..."
weeks = 10.times.map { |i| i.weeks.ago.beginning_of_week }.uniq

digest_count = 0
Topic.find_each do |topic|
  weeks.each do |week_of|
    template = digest_templates.sample
    item1, item2, item3 = template[:items].sample(3)

    content = <<~HTML
      <h3>#{template[:heading]}</h3>
      <ul>
        <li>#{item1}</li>
        <li>#{item2}</li>
        <li>#{item3}</li>
      </ul>
      <p>Stay tuned for more updates next week.</p>
    HTML

    TopicDigest.find_or_create_by!(topic: topic, week_of: week_of) do |d|
      d.content = content
      d.scraped_data = { source: "seed", generated_at: Time.current }.to_json
    end
    digest_count += 1
  end
end

puts "Created #{digest_count} digests."

# Seed Ahoy email tracking data for charts
puts "\nSeeding email tracking data..."
subscriber_ids = User.joins(:roles).where(roles: { name: "subscriber" }).pluck(:id)
all_topic_ids = Topic.pluck(:id)

# Generate email data for 12 weeks
12.downto(0) do |week_offset|
  week_start = week_offset.weeks.ago.beginning_of_week
  week_end = week_offset.weeks.ago.end_of_week

  # Send emails to ~70-90% of subscribers each week
  send_rate = rand(0.7..0.9)
  recipients = subscriber_ids.sample((subscriber_ids.length * send_rate).round)

  recipients.each do |user_id|
    sent_at = week_start + rand(0..2).days + rand(8..18).hours + rand(0..59).minutes

    # Open rate varies by week (simulating improvement over time)
    base_open_rate = 0.35 + (12 - week_offset) * 0.02
    opened = rand < (base_open_rate + rand(-0.1..0.1))

    message = Ahoy::Message.create!(
      user_type: "User",
      user_id: user_id,
      to: User.find(user_id).email,
      mailer: "UserMailer#topic_digest",
      subject: "Mboka Intelligence Digest",
      sent_at: sent_at,
      opened_at: opened ? sent_at + rand(1..48).hours : nil,
      campaign: "weekly_digest"
    )

    # Some clicks
    if opened && rand < 0.3
      rand(1..3).times do
        Ahoy::Click.create!(
          campaign: "weekly_digest",
          token: SecureRandom.hex(16)
        )
      end
    end
  end
end

puts "Created #{Ahoy::Message.count} email messages, #{Ahoy::Message.where.not(opened_at: nil).count} opened, #{Ahoy::Click.count} clicks."

# Seed favorites - each subscriber gets at least 50
puts "\nSeeding favorites..."
all_digests = TopicDigest.all.to_a

User.where(id: User.joins(:roles).where(roles: { name: "subscriber" }).pluck(:id)).find_each do |user|
  user_topic_ids = user.topic_ids
  relevant_digests = all_digests.select { |d| user_topic_ids.include?(d.topic_id) }

  # Combine relevant digests with random other digests to reach 50+
  available = relevant_digests.dup
  other_digests = (all_digests - relevant_digests).shuffle
  while available.size < 50 && other_digests.any?
    available << other_digests.pop
  end

  count = [50, available.size].min
  selected = available.sample(count)

  selected.each do |digest|
    Favorite.find_or_create_by!(user: user, topic_digest: digest)
  end

  puts "#{user.email}: #{user.favorites.count} favorites"
end

puts ""
puts "=== Summary ==="
puts "Users: #{User.count} (#{User.joins(:roles).where(roles: { name: 'admin' }).count} admin, #{User.joins(:roles).where(roles: { name: 'moderator' }).count} moderators, #{User.joins(:roles).where(roles: { name: 'subscriber' }).count} subscribers)"
puts "Topics: #{Topic.count}"
puts "Digests: #{TopicDigest.count}"
puts "Favorites: #{Favorite.count}"
puts ""
puts "=== Login Credentials ==="
puts "Admin:     admin@thoth.africa / password123"
puts "Moderator: faith@mboka.dnrstudios.co.ke / password123"
puts "Moderator: brian@mboka.dnrstudios.co.ke / password123"
puts "Subscriber: wanjiru@example.com / password123"
puts "========================="
