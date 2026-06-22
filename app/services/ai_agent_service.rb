# frozen_string_literal: true

class AiAgentService
  def self.call(topics:, designation:)
    new(topics, designation).execute
  end

  def initialize(topics, designation)
    @topics = topics
    @designation = designation
  end

  def execute
    raw_data = scrape_web_for_topics
    analyze_and_summarize(raw_data)
  end

  private

  def anthropic_api_key
    ApiKeyCache.read("anthropic_api_key") ||
      Rails.application.credentials.dig(:anthropic, :api_key)
  end

  def scrape_web_for_topics
    client = Anthropic::Client.new(api_key: anthropic_api_key)

    response = client.messages(
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: "Search and compile the latest news, articles, and developments about: #{@topics.join(', ')}. Focus on recent developments from the past week. Return the raw findings with source URLs."
        }
      ]
    )

    response.content[0].text
  rescue StandardError => e
    Rails.logger.error("AiAgentService scrape error: #{e.message}")
    "Unable to fetch data for #{@topics.join(', ')} at this time."
  end

  def analyze_and_summarize(raw_data)
    client = Anthropic::Client.new(api_key: anthropic_api_key)

    prompt = <<~TEXT
      You are an expert research agent. Analyze the following raw data for a professional working as a #{@designation}.
      Filter and summarize the most impactful insights specifically tailored to these topics: #{@topics.join(', ')}.

      Raw Data:
      #{raw_data}

      Format the output beautifully in Markdown suitable for an email newsletter.
      Include links to source articles where available.
      Focus on actionable insights and key takeaways.
    TEXT

    response = client.messages(
      model: "claude-sonnet-4-20250514",
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    )

    response.content[0].text
  rescue StandardError => e
    Rails.logger.error("AiAgentService analysis error: #{e.message}")
    "Unable to analyze data for #{@topics.join(', ')} at this time."
  end
end
