class Rack::Attack
  redis = Redis.new(REDIS_CONFIG)

  # Extract real IP address from Cloudflare header if present
  def self.real_ip(req)
    req.get_header('HTTP_CF_CONNECTING_IP') || req.ip
  end

  def self.authenticated?(req)
    warden = req.env['warden']
    warden && warden.user.present?
  end

  # Throttle all graphql requests by IP address
  throttle('api/graphql', limit: proc { |req|
    if authenticated?(req)
      CheckConfig.get('api_rate_limit_authenticated', 1000, :integer)
    else
      CheckConfig.get('api_rate_limit', 100, :integer)
    end
  }, period: 60.seconds) do |req|
    real_ip(req) if req.path == '/api/graphql'
  end

  # Blocklist IP addresses that are permanently blocked
  blocklist('block aggressive IPs') do |req|
    redis.get("block:#{real_ip(req)}") == "true"
  end

  # Response to blocked requests
  self.blocklisted_responder = lambda do |req|
    [403, {}, ['Blocked - Your IP has been permanently blocked due to suspicious activity.']]
  end
end
