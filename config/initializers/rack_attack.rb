class Rack::Attack
  redis = Redis.new(REDIS_CONFIG)

  # Extract real IP address from Cloudflare header if present
  def self.real_ip(req)
    req.get_header('HTTP_CF_CONNECTING_IP') || req.ip
  end

  # Throttle all graphql requests by IP address
  throttle('api/graphql', limit: proc { CheckConfig.get('api_rate_limit', 100, :integer) }, period: 60.seconds) do |req|
    real_ip(req) if req.path == '/api/graphql'
  end

  # Blocklist IP addresses that are permanently blocked
  blocklist('block aggressive IPs') do |req|
    redis.get("block:#{real_ip(req)}") == "true"
  end

  # Track excessive login attempts for permanent blocking
  track('track excessive logins/ip') do |req|
    if req.path == '/api/users/sign_in' && req.post?
      ip = real_ip(req)
      begin
        # Increment the counter for the IP and check if it should be blocked
        count = redis.incr("track:#{ip}")
        redis.expire("track:#{ip}", 3600) # Set the expiration time to 1 hour

        # Add IP to blocklist if count exceeds the threshold
        if count.to_i >= CheckConfig.get('login_block_limit', 100, :integer)
          redis.set("block:#{ip}", true)  # No expiration
        end
      rescue => e
        Rails.logger.error("Rack::Attack Error: #{e.message}")
      end

      ip
    end
  end

  # Response to blocked requests
  self.blocklisted_responder = lambda do |req|
    [403, {}, ['Blocked - Your IP has been permanently blocked due to suspicious activity.']]
  end
end
