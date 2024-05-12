class Rack::Attack
  # Configure Cache
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new

  # Allow all local traffic
  safelist('allow-localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Blocklist IP addresses that are permanently blocked
  blocklist('block aggressive IPs') do |req|
    # Use Redis to check if an IP is stored as blocked
    Rails.cache.fetch("block:#{req.ip}") { false }
  end

  # Track excessive login attempts for permanent blocking
  track('track excessive logins/ip') do |req|
    if req.path == '/api/users/sign_in' && req.post?
      # Increment the counter for the IP and check if it should be blocked
      count = Rails.cache.increment("track:#{req.ip}")
      Rails.cache.write("track:#{req.ip}", count, expires_in: 1.hour)

      # Permanently block if count exceeds the threshold (e.g., 100 attempts in 1 hour)
      if count > CheckConfig.get('login_block_limit', 100, :integer)
        Rails.cache.write("block:#{req.ip}", true)  # No expiration
      end

      req.ip
    end
  end

  # Response to blocked requests
  self.blocklisted_response = lambda do |env|
    [ 403, {}, ['Blocked - Your IP has been permanently blocked due to suspicious activity.']]
  end

  # Throttle all graphql requests by IP address
  throttle('api/graphql', limit:  proc { CheckConfig.get('api_rate_limit', 100, :integer) }, period: 60.seconds) do |req|
    req.ip if req.path == '/api/graphql'
  end
end
