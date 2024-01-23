class Rack::Attack
  # Throttle login attempts by IP address
  throttle('logins/ip', limit: ChheckConfig.get('login_rate_limit', 10).to_i, period: 60.seconds) do |req|
    if req.path == '/api/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  throttle('logins/email', limit: ChheckConfig.get('login_rate_limit', 10).to_i, period: 60.seconds) do |req|
    if req.path == '/api/users/sign_in' && req.post?
      # Return the email if present, nil otherwise
      req.params['user']['email'].presence if req.params['user']
    end
  end

   # Throttle all graphql requests by IP address
   throttle('api/graphql', limit: ChheckConfig.get('api_rate_limit', 100).to_i, period: 60.seconds) do |req|
    req.ip if req.path == '/api/graphql'
  end
end
