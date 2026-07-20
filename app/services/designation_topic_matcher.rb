# frozen_string_literal: true

class DesignationTopicMatcher
  DESIGNATION_MAP = {
    # Engineering
    /software\s*(engineer|developer|dev)/i => ["Technology, Software, Data & AI"],
    /frontend\s*(engineer|developer)/i => ["Technology, Software, Data & AI"],
    /backend\s*(engineer|developer)/i => ["Technology, Software, Data & AI"],
    /full\s*stack/i => ["Technology, Software, Data & AI"],
    /mobile\s*(engineer|developer|dev)/i => ["Technology, Software, Data & AI"],
    /devops/i => ["Technology, Software, Data & AI"],
    /site\s*reliability|sre/i => ["Technology, Software, Data & AI"],
    /cloud\s*(engineer|architect)/i => ["Technology, Software, Data & AI"],
    /embedded|iot|hardware/i => ["Technology, Software, Data & AI"],
    /security|cybersecurity|infosec/i => ["Technology, Software, Data & AI"],
    /blockchain|web3|crypto/i => ["Technology, Software, Data & AI"],
    /data\s*(scientist|engineer|analyst)/i => ["Technology, Software, Data & AI"],
    /machine\s*learning|ml\s*engineer|ai/i => ["Technology, Software, Data & AI"],
    /qa|quality|test\s*engineer/i => ["Technology, Software, Data & AI"],
    /architect|solutions?\s*architect/i => ["Technology, Software, Data & AI"],

    # Design
    /product\s*designer|ux\s*designer|ui\s*designer|ui\/ux/i => ["Technology, Software, Data & AI"],
    /graphic\s*designer|visual\s*designer/i => ["Media, Entertainment & Creative Industries", "Marketing, Advertising, Sales & Communications"],
    /design\s*lead|design\s*director/i => ["Technology, Software, Data & AI", "Business, Management & Consulting"],

    # Product & Management
    /product\s*manager|product\s*owner/i => ["Business, Management & Consulting"],
    /project\s*manager|program\s*manager/i => ["Business, Management & Consulting"],
    /scrum\s*master|agile/i => ["Business, Management & Consulting"],

    # Business & Entrepreneurship
    /founder|co-?founder|ceo|cto|cfo|coo/i => ["Entrepreneurship, Startups & Innovation", "Business, Management & Consulting"],
    /entrepreneur|startup/i => ["Entrepreneurship, Startups & Innovation"],
    /business\s*(analyst|developer|development)/i => ["Business, Management & Consulting", "Marketing, Advertising, Sales & Communications"],
    /marketing\s*(manager|director|lead|specialist)/i => ["Marketing, Advertising, Sales & Communications"],
    /digital\s*marketer|growth\s*hacker/i => ["Marketing, Advertising, Sales & Communications", "Entrepreneurship, Startups & Innovation"],
    /social\s*media/i => ["Marketing, Advertising, Sales & Communications"],

    # NGO & Social Impact
    /ngo|non-?profit|npo/i => ["International Development & Humanitarian Work"],
    /program\s*officer|program\s*coordinator/i => ["International Development & Humanitarian Work", "Government, Public Policy & Diplomacy"],
    /community\s*manager|community\s*organizer/i => ["Community Development, Youth & Inclusion", "International Development & Humanitarian Work"],
    /social\s*enterprise|impact/i => ["International Development & Humanitarian Work", "Climate, Environment & Conservation"],
    /monitoring|evaluation|m&e/i => ["Technology, Software, Data & AI", "International Development & Humanitarian Work"],

    # Research & Academia
    /researcher|research\s*(officer|scientist|fellow)/i => ["Science, Research & Innovation", "Education, Training & Academia"],
    /professor|lecturer|academic/i => ["Education, Training & Academia"],
    /student|intern|undergraduate|postgraduate/i => ["Education, Training & Academia"],

    # Sector-specific
    /fintech|finance|banking|financial/i => ["Finance, Banking, Accounting & Insurance"],
    /healthtech|health|medical|healthcare/i => ["Health, Medicine & Life Sciences"],
    /edtech|education|teacher/i => ["Education, Training & Academia"],
    /agritech|agriculture|farming/i => ["Agriculture, Food & Agribusiness"],
    /climate|sustainability|environment|green/i => ["Climate, Environment & Conservation"],

    # Remote & General
    /remote|freelance|consultant/i => ["Business, Management & Consulting"],
    /operations|logistics|supply\s*chain/i => ["Transport, Logistics & Supply Chain", "Business, Management & Consulting"],
    /hr|human\s*resources|talent/i => ["Business, Management & Consulting"],
    /legal|lawyer|attorney/i => ["Law, Governance, Justice & Human Rights"],
    /journalist|writer|content|media/i => ["Media, Entertainment & Creative Industries", "Marketing, Advertising, Sales & Communications"]
  }.freeze

  FALLBACK_TOPICS = ["Business, Management & Consulting", "Technology, Software, Data & AI"].freeze

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
