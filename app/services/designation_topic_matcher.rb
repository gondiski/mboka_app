# frozen_string_literal: true

class DesignationTopicMatcher
  DESIGNATION_MAP = {
    # Engineering
    /software\s*(engineer|developer|dev)/i => ["Software Engineering", "Full Stack Development"],
    /frontend\s*(engineer|developer)/i => ["Frontend Development", "Software Engineering"],
    /backend\s*(engineer|developer)/i => ["Backend Development", "Software Engineering"],
    /full\s*stack/i => ["Full Stack Development", "Software Engineering"],
    /mobile\s*(engineer|developer|dev)/i => ["Mobile Development", "Software Engineering"],
    /devops/i => ["DevOps & Cloud", "Software Engineering"],
    /site\s*reliability|sre/i => ["DevOps & Cloud", "Cybersecurity"],
    /cloud\s*(engineer|architect)/i => ["DevOps & Cloud", "Software Engineering"],
    /embedded|iot|hardware/i => ["Embedded Systems & IoT", "Software Engineering"],
    /security|cybersecurity|infosec/i => ["Cybersecurity", "DevOps & Cloud"],
    /blockchain|web3|crypto/i => ["Blockchain & Web3", "Software Engineering"],
    /data\s*(scientist|engineer|analyst)/i => ["Data Science & AI", "Software Engineering"],
    /machine\s*learning|ml\s*engineer|ai/i => ["Data Science & AI", "Software Engineering"],
    /qa|quality|test\s*engineer/i => ["Software Engineering", "DevOps & Cloud"],
    /architect|solutions?\s*architect/i => ["Software Engineering", "DevOps & Cloud"],

    # Design
    /product\s*designer|ux\s*designer|ui\s*designer|ui\/ux/i => ["Product Design", "Product Management"],
    /graphic\s*designer|visual\s*designer/i => ["Product Design", "Digital Marketing"],
    /design\s*lead|design\s*director/i => ["Product Design", "Product Management"],

    # Product & Management
    /product\s*manager|product\s*owner/i => ["Product Management", "Startup Accelerators"],
    /project\s*manager|program\s*manager/i => ["Product Management", "Business & Entrepreneurship"],
    /scrum\s*master|agile/i => ["Product Management", "Software Engineering"],

    # Business & Entrepreneurship
    /founder|co-?founder|ceo|cto|cfo|coo/i => ["Business & Entrepreneurship", "Startup Accelerators", "Venture Capital & Funding"],
    /entrepreneur|startup/i => ["Business & Entrepreneurship", "Startup Accelerators", "Startup Incubators"],
    /business\s*(analyst|developer|development)/i => ["Business & Entrepreneurship", "Digital Marketing"],
    /marketing\s*(manager|director|lead|specialist)/i => ["Digital Marketing", "Business & Entrepreneurship"],
    /digital\s*marketer|growth\s*hacker/i => ["Digital Marketing", "Startup Accelerators"],
    /social\s*media/i => ["Digital Marketing", "Social Enterprise"],

    # NGO & Social Impact
    /ngo|non-?profit|npo/i => ["NGO & Non-Profit Grants", "Social Enterprise"],
    /program\s*officer|program\s*coordinator/i => ["NGO & Non-Profit Grants", "Government Grants"],
    /community\s*manager|community\s*organizer/i => ["Social Enterprise", "NGO & Non-Profit Grants"],
    /social\s*enterprise|impact/i => ["Social Enterprise", "NGO & Non-Profit Grants", "Climate & Sustainability"],
    /monitoring|evaluation|m&e/i => ["NGO & Non-Profit Grants", "Research Fellowships"],

    # Research & Academia
    /researcher|research\s*(officer|scientist|fellow)/i => ["Research Fellowships", "Academic Scholarships"],
    /professor|lecturer|academic/i => ["Academic Scholarships", "Research Fellowships"],
    /student|intern|undergraduate|postgraduate/i => ["Academic Scholarships", "Remote Jobs"],

    # Sector-specific
    /fintech|finance|banking|financial/i => ["Fintech Opportunities", "Venture Capital & Funding"],
    /healthtech|health|medical|healthcare/i => ["Healthtech Opportunities", "Social Enterprise"],
    /edtech|education|teacher/i => ["Edtech Opportunities", "Academic Scholarships"],
    /agritech|agriculture|farming/i => ["Agritech Opportunities", "Climate & Sustainability"],
    /climate|sustainability|environment|green/i => ["Climate & Sustainability", "Social Enterprise"],

    # Remote & General
    /remote|freelance|consultant/i => ["Remote Jobs", "Business & Entrepreneurship"],
    /operations|logistics|supply\s*chain/i => ["Business & Entrepreneurship", "Agritech Opportunities"],
    /hr|human\s*resources|talent/i => ["Business & Entrepreneurship", "Remote Jobs"],
    /legal|lawyer|attorney/i => ["Business & Entrepreneurship", "NGO & Non-Profit Grants"],
    /journalist|writer|content|media/i => ["Digital Marketing", "Remote Jobs"]
  }.freeze

  FALLBACK_TOPICS = ["Remote Jobs", "Business & Entrepreneurship"].freeze

  def self.match(designation)
    return [] if designation.blank?

    matched = []

    DESIGNATION_MAP.each do |pattern, topics|
      if designation.match?(pattern)
        matched.concat(topics)
        break
      end
    end

    matched = matched.uniq

    matched = FALLBACK_TOPICS if matched.empty?

    matched.map { |name| Topic.find_or_create_by!(name: name) }
  end

  def self.assign_to_user(user)
    topics = match(user.designation)
    user.topics = topics
    topics
  end
end
