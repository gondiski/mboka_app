# frozen_string_literal: true

class TopicConsolidationService
  NEW_TOPICS = [
    "Agriculture, Food & Agribusiness",
    "Arts, Culture & Heritage",
    "Media, Entertainment & Creative Industries",
    "Fashion, Beauty & Personal Care",
    "Business, Management & Consulting",
    "Entrepreneurship, Startups & Innovation",
    "Finance, Banking, Accounting & Insurance",
    "Technology, Software, Data & AI",
    "Telecommunications & Digital Infrastructure",
    "Engineering & Manufacturing",
    "Energy, Water & Utilities",
    "Climate, Environment & Conservation",
    "Construction, Architecture & Real Estate",
    "Transport, Logistics & Supply Chain",
    "Health, Medicine & Life Sciences",
    "Education, Training & Academia",
    "Science, Research & Innovation",
    "Government, Public Policy & Diplomacy",
    "Law, Governance, Justice & Human Rights",
    "International Development & Humanitarian Work",
    "Community Development, Youth & Inclusion",
    "Marketing, Advertising, Sales & Communications",
    "Retail, E-commerce & Consumer Goods",
    "Hospitality, Tourism, Travel & Events",
    "Sports, Fitness & Recreation",
    "Skilled Trades, Artisan Work & Technical Services"
  ].freeze

  MAPPING = {
    "Software Engineering" => "Technology, Software, Data & AI",
    "Data Science & AI" => "Technology, Software, Data & AI",
    "Product Design" => "Technology, Software, Data & AI",
    "Product Management" => "Business, Management & Consulting",
    "DevOps & Cloud" => "Technology, Software, Data & AI",
    "Cybersecurity" => "Technology, Software, Data & AI",
    "Mobile Development" => "Technology, Software, Data & AI",
    "Frontend Development" => "Technology, Software, Data & AI",
    "Backend Development" => "Technology, Software, Data & AI",
    "Full Stack Development" => "Technology, Software, Data & AI",
    "NGO & Non-Profit Grants" => "International Development & Humanitarian Work",
    "Government Grants" => "Government, Public Policy & Diplomacy",
    "Research Fellowships" => "Science, Research & Innovation",
    "Academic Scholarships" => "Education, Training & Academia",
    "Startup Accelerators" => "Entrepreneurship, Startups & Innovation",
    "Startup Incubators" => "Entrepreneurship, Startups & Innovation",
    "Venture Capital & Funding" => "Entrepreneurship, Startups & Innovation",
    "Angel Investor Programs" => "Entrepreneurship, Startups & Innovation",
    "Remote Jobs" => "Business, Management & Consulting",
    "Tech Jobs Kenya" => "Technology, Software, Data & AI",
    "Fintech Opportunities" => "Finance, Banking, Accounting & Insurance",
    "Healthtech Opportunities" => "Health, Medicine & Life Sciences",
    "Edtech Opportunities" => "Education, Training & Academia",
    "Agritech Opportunities" => "Agriculture, Food & Agribusiness",
    "Climate & Sustainability" => "Climate, Environment & Conservation",
    "Social Enterprise" => "International Development & Humanitarian Work",
    "Digital Marketing" => "Marketing, Advertising, Sales & Communications",
    "Blockchain & Web3" => "Technology, Software, Data & AI",
    "Embedded Systems & IoT" => "Technology, Software, Data & AI",
    "Business & Entrepreneurship" => "Entrepreneurship, Startups & Innovation",
    "Internships" => "Education, Training & Academia",
    "Jobs" => "Business, Management & Consulting",
    "Grants" => "International Development & Humanitarian Work",
    "Technology and AI" => "Technology, Software, Data & AI",
    "Climate and green jobs" => "Climate, Environment & Conservation",
    "Health" => "Health, Medicine & Life Sciences",
    "NGO / development work" => "International Development & Humanitarian Work",
    "Graduate trainee programs" => "Education, Training & Academia",
    "Media" => "Media, Entertainment & Creative Industries",
    "Scholarships" => "Education, Training & Academia",
    "film and content creation" => "Media, Entertainment & Creative Industries",
    "Training programs" => "Education, Training & Academia",
    "Agriculture and food systems" => "Agriculture, Food & Agribusiness",
    "Creative industry opportunities" => "Media, Entertainment & Creative Industries",
    "Remote work opportunities" => "Business, Management & Consulting",
    "Competitions and challenges" => "Community Development, Youth & Inclusion",
    "Volunteer opportunities" => "International Development & Humanitarian Work",
    "Mentorship opportunities" => "Education, Training & Academia",
    "Fellowships" => "Education, Training & Academia",
    "Content creator opportunities" => "Media, Entertainment & Creative Industries",
    "Business funding" => "Entrepreneurship, Startups & Innovation",
    "TVET / skills opportunities" => "Education, Training & Academia",
    "Agribusiness opportunities" => "Agriculture, Food & Agribusiness",
    "Education" => "Education, Training & Academia",
    "Finance and investment" => "Finance, Banking, Accounting & Insurance",
    "Construction and technical trades" => "Construction, Architecture & Real Estate",
    "Fashion and beauty" => "Fashion, Beauty & Personal Care",
    "Arts and culture" => "Arts, Culture & Heritage",
    "Sports" => "Sports, Fitness & Recreation",
    "Medical engineering" => "Health, Medicine & Life Sciences",
    "Hospitality and tourism" => "Hospitality, Tourism, Travel & Events",
    "Logistics" => "Transport, Logistics & Supply Chain",
    "Graphic Design" => "Media, Entertainment & Creative Industries",
    "Events" => "Hospitality, Tourism, Travel & Events",
    "Communicqtion and Public Relations" => "Marketing, Advertising, Sales & Communications",
    "Civil Engineering" => "Engineering & Manufacturing",
    "Mechanical" => "Engineering & Manufacturing",
    "Phone Repair." => "Skilled Trades, Artisan Work & Technical Services",
    "International Relations and Diplomacy" => "Government, Public Policy & Diplomacy",
    "Fitness" => "Sports, Fitness & Recreation",
    "Mechanic" => "Skilled Trades, Artisan Work & Technical Services",
    "Engineering" => "Engineering & Manufacturing",
    "Moderation" => "Media, Entertainment & Creative Industries",
    "Administration" => "Business, Management & Consulting",
    "Customer service" => "Retail, E-commerce & Consumer Goods",
    "psychology" => "Health, Medicine & Life Sciences",
    "Interior design" => "Construction, Architecture & Real Estate",
    "Design" => "Media, Entertainment & Creative Industries",
    "Law and project Management" => "Law, Governance, Justice & Human Rights",
    "Office Admin" => "Business, Management & Consulting",
    "Renewable energy(solar)" => "Energy, Water & Utilities",
    "Data Analysis and Monitoring And Evaluation" => "Technology, Software, Data & AI",
    "Remote jobs and virtual assistant jobs" => "Business, Management & Consulting",
    "Mechanism" => "Engineering & Manufacturing",
    "Security management" => "Law, Governance, Justice & Human Rights",
    "Deejaying" => "Media, Entertainment & Creative Industries",
    "Music" => "Media, Entertainment & Creative Industries",
    "Sales" => "Marketing, Advertising, Sales & Communications"
  }.freeze

  def self.execute
    Rails.logger.info("Starting Topic Consolidation...")

    # Ensure all new topics exist
    new_topic_records = NEW_TOPICS.each_with_object({}) do |topic_name, hash|
      hash[topic_name] = Topic.find_or_create_by!(name: topic_name)
    end

    ActiveRecord::Base.transaction do
      # Migrate users and their topics
      UserTopic.includes(:topic, :user).find_each do |ut|
        old_topic_name = ut.topic.name
        next if NEW_TOPICS.include?(old_topic_name)

        new_category_name = MAPPING[old_topic_name] || "Business, Management & Consulting"
        new_topic = new_topic_records[new_category_name]

        # Use find_or_create to avoid duplicate UserTopics
        UserTopic.find_or_create_by!(user_id: ut.user_id, topic_id: new_topic.id)
        
        # We can destroy the old UserTopic relation since it's mapped to the new one
        ut.destroy!
      end

      # Update existing TopicDigests so we can safely delete old topics
      TopicDigest.includes(:topic).find_each do |digest|
        old_topic_name = digest.topic.name
        next if NEW_TOPICS.include?(old_topic_name)

        new_category_name = MAPPING[old_topic_name] || "Business, Management & Consulting"
        new_topic = new_topic_records[new_category_name]

        if TopicDigest.exists?(topic_id: new_topic.id, week_of: digest.week_of)
          digest.destroy!
        else
          digest.update!(topic_id: new_topic.id)
        end
      end

      # Now it is safe to completely destroy old topics
      Topic.where.not(name: NEW_TOPICS).destroy_all
    end

    Rails.logger.info("Topic Consolidation Complete!")
  end
end
