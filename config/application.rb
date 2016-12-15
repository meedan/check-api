require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Checkdesk
  class Application < Rails::Application
    config.generators do |g|
      g.javascripts false
      g.stylesheets false
      g.template_engine false
      g.helper false
      g.assets false
    end

    config.autoload_paths << Rails.root.join('app', 'graph', 'mutations')
    config.autoload_paths << Rails.root.join('app', 'graph', 'types')

    config.active_record.raise_in_transactional_callbacks = true
    config.autoload_paths << "#{config.root}/app/models/annotations"
    config.autoload_paths << "#{config.root}/app/models/search"
    config.autoload_paths += %W(#{config.root}/lib)

    config.action_mailer.delivery_method = :smtp

    cfg = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
    if !cfg['smtp_user'].blank? && !cfg['smtp_pass'].blank? && !Rails.env.test?
      config.action_mailer.smtp_settings = {
        address:              cfg['smtp_host'],
        port:                 cfg['smtp_port'],
        user_name:            cfg['smtp_user'],
        password:             cfg['smtp_pass'],
        authentication:       'plain',
        enable_starttls_auto: true
      }
    end

    config.middleware.insert_before Warden::Manager, Rack::Cors do
      allow do
        origins Regexp.new(cfg['checkdesk_client'])
        resource '*',
          headers: [cfg['authorization_header'], 'Content-Type', 'Accept', 'X-Checkdesk-Context-Team', 'X-Requested-With', 'Origin'],
          methods: [:get, :post, :delete, :options]
      end
    end

    config.action_dispatch.default_headers.merge!({
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Request-Method' => '*'
    })
  end
end
