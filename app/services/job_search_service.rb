# frozen_string_literal: true

require "net/http"
require "json"

class JobSearchService
  def self.call(topic_name:, schedule_date: nil)
    new(topic_name, schedule_date).fetch_jobs
  end

  def initialize(topic_name, schedule_date = nil)
    @topic_name = topic_name
    @schedule_date = schedule_date || Date.current
    @api_key = ApiKeyCache.read("serpapi_key")
  end

  def fetch_jobs
    return [] if @api_key.blank?

    jobs = search_google_jobs
    results = format_results(jobs)
    results.present? ? results : []
  rescue StandardError => e
    Rails.logger.error("JobSearchService error: #{e.message}")
    []
  end

  private

  def search_google_jobs
    fetch_jobs_for_location("#{@topic_name} jobs Kenya")
  end

  def fetch_jobs_for_location(query)
    uri = URI("https://serpapi.com/search.json")
    params = {
      engine: "google_jobs",
      q: query,
      location: "Kenya",
      api_key: @api_key,
      hl: "en",
      gl: "ke",
      chips: "date_posted:#{date_chip}"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body, symbolize_names: true)

    data.dig(:jobs_results) || []
  rescue StandardError => e
    Rails.logger.error("JobSearchService fetch_jobs_for_location error: #{e.message}")
    []
  end

  def date_chip
    days_until = (@schedule_date - Date.current).to_i
    if days_until <= 3
      "r86400"       # past 24 hours
    elsif days_until <= 7
      "r604800"      # past week
    else
      "r2592000"     # past month
    end
  end

  def format_results(jobs)
    jobs.first(5).map do |job|
      {
        title: job[:title],
        company: job[:company_name],
        location: job[:location],
        description: job[:description]&.truncate(200),
        link: job[:share_link] || job[:link],
        via: job[:via],
        posted_at: job[:detected_extensions]&.[](:posted_at)
      }
    end
  end
end
