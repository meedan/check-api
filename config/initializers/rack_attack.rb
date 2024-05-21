class Rack::Attack
  # Throttle all graphql requests by IP address
  throttle('api/graphql', limit:  proc { CheckConfig.get('api_rate_limit', 100, :integer) }, period: 60.seconds) do |req|
    req.ip if req.path == '/api/graphql'
  end

  # Blocklist IP addresses that are permanently blocked
  blocklist('block aggressive IPs') do |req|
    Rails.cache.fetch("block:#{req.ip}") { false }
  end

  # Track excessive login attempts for permanent blocking
  track('track excessive logins/ip') do |req|
    if req.path == '/api/users/sign_in' && req.post?
      # Increment the counter for the IP and check if it should be blocked
      count = Rails.cache.increment("track:#{req.ip}") || 0
      Rails.cache.write("track:#{req.ip}", count, expires_in: 1.hour)

      # Add IP to blocklist if count exceeds the threshold
      if count >= CheckConfig.get('login_block_limit', 100, :integer)
        Rails.cache.write("block:#{req.ip}", true)  # No expiration
      end

      req.ip
    end
  end

  # Response to blocked requests
  self.blocklisted_response = lambda do |env|
    [ 403, {}, ['Blocked - Your IP has been permanently blocked due to suspicious activity.']]
  end
end
