# frozen_string_literal: true

class AiAgentService
  def self.call(topics:, designation:, jobs: [])
    new(topics, designation, jobs).execute
  end

  def initialize(topics, designation, jobs)
    @topics = topics
    @designation = designation
    @jobs = jobs
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

    response = client.messages.create(
      model: "claude-sonnet-4-6",
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
    Rails.logger.error("AiAgentService scrape error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end

  def analyze_and_summarize(raw_data)
    client = Anthropic::Client.new(api_key: anthropic_api_key)

    prompt = <<~TEXT
      You are an expert research agent. Create an email newsletter digest for a professional interested in #{@topics.join(', ')}.

      ## SECTION 1: Raw findings to analyze
      #{raw_data}

      #{job_market_section}

      ## Instructions
      Create a very simple, brief email newsletter. Use the following exact structure:

      <h2>Key Insights</h2>
      <p>[Write a concise summary of the most impactful news and developments. This text MUST BE STRICTLY UNDER 500 CHARACTERS.]</p>

      <h2>Job Market Update</h2>
      <p>[Write a brief 1-2 sentence summary of the hiring trends based on the jobs below. If no jobs exist, skip this entire section.]</p>

      ## CRITICAL FORMAT RULES
      - Output ONLY clean, semantic HTML. Do NOT use Markdown.
      - Keep the HTML extremely simple for email clients (just <h2>, <p>, <strong>, <a href="...">).
      - Do NOT include <html>, <head>, <body>, or <style> tags — just the inner content HTML.
      - You must strictly count characters and ensure the Key Insights paragraph is 500 characters or fewer.
    TEXT

    response = client.messages.create(
      model: "claude-sonnet-4-6",
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
    Rails.logger.error("AiAgentService analysis error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end

  def job_market_section
    return "## Job Listings\nNo job listings available this week." if @jobs.blank?

    listings = @jobs.map do |job|
      line = "- **#{job[:title]}** at #{job[:company]}"
      line += " (#{job[:location]})" if job[:location].present?
      line += " — #{job[:description]}" if job[:description].present?
      line
    end.join("\n")

    <<~TEXT
      ## Job Listings (from Google Jobs)
      #{listings}
    TEXT
  end
end
