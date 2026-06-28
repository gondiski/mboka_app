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
      1. Start with a "Job Market Update" section that summarizes the job listings above — highlight key roles, hiring trends, notable companies, and locations. If no jobs were found, skip this section entirely.
      2. Then include a "Key Insights" section with the most impactful news and developments. THIS SECTION MUST BE 240 CHARACTERS OR LESS — be extremely concise and punchy.
      3. End with a "Key Takeaways" section with 3-4 actionable bullet points.

      ## CRITICAL FORMAT RULES
      - Output ONLY clean, semantic HTML. Do NOT use Markdown.
      - Use <h2> for section headings, <p> for paragraphs, <ul>/<li> for bullet points, <a href="..."> for links, <strong> for emphasis.
      - Do NOT include <html>, <head>, <body>, or <style> tags — just the inner content HTML.
      - The Key Insights section content (not the heading) must be 240 characters or fewer.
      - Be concise and actionable — this is for a busy professional.
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
