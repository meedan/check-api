if Rails.env.production?
  Rails.application.config.middleware.insert_before Rack::Attack, Rack::Cloudflare
end
