# frozen_string_literal: true

require "rss"
require "open-uri"

class RssOpportunityService
  URLS = %w[
    https://opportunitydesk.org/category/grants/feed/
    https://opportunitydesk.org/category/fellowships/feed/
    https://opportunitydesk.org/feed/
    https://vc4a.com/feed/
  ].freeze

  def self.fetch
    new.fetch
  end

  def fetch
    all_items = []

    URLS.each do |url|
      begin
        URI.open(url) do |rss_file|
          rss = RSS::Parser.parse(rss_file, false)
          all_items += rss.items
        end
      rescue StandardError => e
        Rails.logger.error("RssOpportunityService fetch error for #{url}: #{e.message}")
      end
    end

    all_items.uniq!(&:link)

    # Filter to prioritize items that mention grants, fellowships, scholarships, sponsorships, or funding
    keywords = /grant|fellowship|scholarship|sponsorship|funding|startup|venture|seed/i
    relevant_items = all_items.select do |item|
      item.title.to_s.match?(keywords) || 
        item.categories.any? { |c| c.content.to_s.match?(keywords) }
    end

    # Fallback to all if none match, but limit to 10
    items_to_process = relevant_items.any? ? relevant_items : all_items
    
    items_to_process.first(15).map do |item|
      {
        title: item.title,
        company: "Opportunity Desk",
        location: "Africa / Global",
        description: ActionView::Base.full_sanitizer.sanitize(item.description)&.truncate(200),
        link: item.link,
        via: "RSS Feed",
        posted_at: item.pubDate&.strftime("%B %d, %Y")
      }
    end
  rescue StandardError => e
    Rails.logger.error("RssOpportunityService fetch error: #{e.message}")
    []
  end
end
