# frozen_string_literal: true

require "rss"
require "open-uri"

class RssOpportunityService
  URL = "https://opportunitydesk.org/feed/"

  def self.fetch
    new.fetch
  end

  def fetch
    URI.open(URL) do |rss_file|
      rss = RSS::Parser.parse(rss_file, false)
      rss.items.map do |item|
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
    end
  rescue StandardError => e
    Rails.logger.error("RssOpportunityService fetch error: #{e.message}")
    []
  end
end
