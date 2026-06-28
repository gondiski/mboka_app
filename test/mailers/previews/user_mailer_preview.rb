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
        <hr style="margin: 24px 0; border: none; border-top: 1px solid #e5e7eb;">
        <h3 style="color: #1e40af; font-size: 16px; margin-bottom: 12px;">
          Recent Kenya Job Openings
        </h3>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
          <tr>
            <td style="padding: 8px 0; border-bottom: 1px solid #f3f4f6;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <a href="#" style="color: #16a34a; font-weight: 600; text-decoration: none; font-size: 14px;">Senior Software Engineer</a>
                    <br>
                    <span style="color: #6b7280; font-size: 13px;">Safaricom &middot; Nairobi, Kenya &middot; <em>2 days ago</em></span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding: 8px 0; border-bottom: 1px solid #f3f4f6;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <a href="#" style="color: #16a34a; font-weight: 600; text-decoration: none; font-size: 14px;">Backend Developer</a>
                    <br>
                    <span style="color: #6b7280; font-size: 13px;">Andela &middot; Remote (Kenya) &middot; <em>5 days ago</em></span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      HTML

      digests = [
        TopicDigest.new(id: 1, topic: topic1, week_of: Date.current.beginning_of_week, content: mock_content),
        TopicDigest.new(id: 2, topic: topic2, week_of: Date.current.beginning_of_week, content: mock_content)
      ]
    end

    UserMailer.topic_digest(user, digests)
  end
end
