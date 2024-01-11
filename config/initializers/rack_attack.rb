class Rack::Attack
  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
    if req.path == '/api/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  throttle('logins/email', limit: 5, period: 60.seconds) do |req|
    if req.path == '/api/users/sign_in' && req.post?
      # Return the email if present, nil otherwise
      req.params['user']['email'].presence if req.params['user']
    end
  end
end
