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
    insights_html = analyze_and_summarize(raw_data)
    # Combine AI insights with formatted job listings into a single content block.
    # The <!-- JOBS_SECTION --> delimiter lets the email template show only insights and top 5 jobs,
    # while the full web view shows everything in sequence.
    if @jobs.present?
      preview_jobs = @jobs.first(5)
      remaining_jobs = @jobs.drop(5)

      preview_html = JobDigestFormatter.format(preview_jobs, title: "Top Opportunities")
      remaining_html = remaining_jobs.any? ? JobDigestFormatter.format(remaining_jobs, title: "More Opportunities") : ""

      "#{insights_html}\n#{preview_html}\n<!-- JOBS_SECTION -->\n#{remaining_html}"
    else
      insights_html
    end
  end

  private

  def anthropic_api_key
    ApiKeyCache.read("anthropic_api_key") ||
      Rails.application.credentials.dig(:anthropic, :api_key)
  end

  def jobs_context
    return "" if @jobs.blank?

    lines = @jobs.map do |job|
      parts = ["• #{job[:title]} at #{job[:company]}"]
      parts << "(#{job[:location]})" if job[:location].present?
      parts << "— #{job[:description]}" if job[:description].present?
      parts << "[Posted: #{job[:posted_at]}]" if job[:posted_at].present?
      parts.join(" ")
    end

    <<~TEXT

      ## REAL-TIME JOB MARKET DATA (from Google Jobs, past 3 days)
      The following are actual job listings currently open in East Africa for this topic:
      #{lines.join("\n")}
    TEXT
  end

  def scrape_web_for_topics
    client = Anthropic::Client.new(api_key: anthropic_api_key)

    prompt = "You are an expert career and industry analyst. Compile a Job Opportunity Radar focusing on the latest market signals, hiring trends, and career developments about: #{@topics.join(', ')}."
    prompt += jobs_context if @jobs.present?
    prompt += "\n\nCRITICAL RULE: If you do not have access to real-time data, DO NOT mention that fact. DO NOT apologize, DO NOT state that your knowledge is cut off, and DO NOT give the user instructions on how to search Google themselves. Instead, confidently provide a highly valuable, forward-looking strategic analysis and evergreen industry trends based on the most recent information you possess."

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
    Rails.logger.error("AiAgentService scrape error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end

  def analyze_and_summarize(raw_data)
    client = Anthropic::Client.new(api_key: anthropic_api_key)

    prompt = <<~TEXT
      You are an expert career and research agent. Create a Job Opportunity Radar email digest for a professional interested in #{@topics.join(', ')}.

      ## SECTION 1: Raw findings to analyze
      #{raw_data}
      #{jobs_context_for_analysis}

      ## Instructions
      Create a very simple, brief email newsletter. Use the following exact structure:

      <h2>Market Signals & Hiring Trends</h2>
      <p>[Write a concise summary of the most impactful hiring trends, skill demands, and career opportunities in this sector. This text MUST BE STRICTLY UNDER 500 CHARACTERS. If job market data was provided, weave in a brief mention of hiring trends (e.g., "Companies like X are actively hiring for Y roles") — do NOT just list the jobs individually.]</p>

      ## CRITICAL FORMAT RULES
      - Output ONLY clean, semantic HTML. Do NOT use Markdown.
      - Keep the HTML extremely simple for email clients (just <h2>, <p>, <strong>, <a href="...">).
      - Do NOT include <html>, <head>, <body>, or <style> tags — just the inner content HTML.
      - You must strictly count characters and ensure the Key Insights paragraph is 500 characters or fewer.
      - NEVER mention that you are an AI. 
      - NEVER mention that real-time data or live links are unavailable. 
      - NEVER instruct the reader to search Google or monitor external websites. 
      - If the raw findings lack specific news, provide a confident, evergreen professional insight or career trend analysis instead. Write with absolute authority.
      - Do NOT list job openings individually — job listings are appended separately. Focus on trends and insights.
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

  def jobs_context_for_analysis
    return "" if @jobs.blank?

    lines = @jobs.map do |job|
      "• #{job[:title]} at #{job[:company]} (#{job[:location]})"
    end

    <<~TEXT

      ## SECTION 2: Current job openings (real data from East Africa)
      These are actual live job postings. Use them to identify hiring trends and market signals:
      #{lines.join("\n")}
    TEXT
  end
end
