# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def topic_digest
    user = User.first || User.new(email: "jane@example.com", full_name: "Jane Doe", unsubscribe_token: "fake-token")
    
    # Try to find existing digests, or create mock ones
    digests = TopicDigest.includes(:topic).limit(2).to_a
    
    if digests.empty?
      # Create mock digests if none exist in the DB
      topic1 = Topic.new(name: "Ruby on Rails")
      topic2 = Topic.new(name: "Artificial Intelligence")
      
      mock_content = <<~HTML
        <h2>Key Insights</h2>
        <p>This week saw major developments in the ecosystem, with new tools released that dramatically simplify backend architecture and deployment workflows for modern web applications.</p>
      HTML

      digests = [
        TopicDigest.new(id: 1, topic: topic1, week_of: Date.current.beginning_of_week, content: mock_content),
        TopicDigest.new(id: 2, topic: topic2, week_of: Date.current.beginning_of_week, content: mock_content)
      ]
    end

    UserMailer.topic_digest(user, digests)
  end
end
