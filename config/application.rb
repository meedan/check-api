require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Check
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

    config.i18n.fallbacks = ['en']
    config.i18n.default_locale = 'en'

    if cfg['locale'].blank?
      config.i18n.available_locales = ["ar","fr","pt","en"] # Do not change manually! Use `rake transifex:languages` instead, or set the `locale` key in your `config/config.yml`
    else
      config.i18n.available_locales = [cfg['locale']].flatten
    end

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
        origins cfg['checkdesk_client']
        resource '*',
          headers: [cfg['authorization_header'], 'Content-Type', 'Accept', 'X-Requested-With', 'Origin'],
          methods: [:get, :post, :delete, :options]
      end
    end

    config.action_dispatch.default_headers.merge!({
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Request-Method' => '*'
    })
  end
end
