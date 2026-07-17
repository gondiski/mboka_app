class Rack::Attack
  # Use Rails cache store (Redis in production, MemoryStore in dev/test)
  Rack::Attack.cache.store = Rails.cache

  # Allow all local traffic
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # General throttling: Limit all IPs to 300 requests per 5 minutes
  # Exclude assets to not count against the limit
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle magic link requests to 5 per minute per IP
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    if req.path == '/magic_links' && req.post?
      req.ip
    end
  end

  # Throttle magic link validation to 10 per minute per IP to prevent brute forcing
  throttle('magic_links_validate/ip', limit: 10, period: 1.minute) do |req|
    if req.path == '/magic_links/v' && req.get?
      req.ip
    end
  end

  # Throttle email tracking opens to prevent abuse
  throttle('email_track_opens/ip', limit: 20, period: 1.minute) do |req|
    if req.path == '/t/open' && req.get?
      req.ip
    end
  end

  # Return a friendly 429 response
  self.throttled_responder = lambda do |env|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: "Too Many Requests", message: "You have exceeded your request limit. Please try again later." }.to_json]
    ]
  end
end
