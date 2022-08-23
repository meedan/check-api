require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Check
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.generators do |g|
      g.javascripts false
      g.stylesheets false
      g.template_engine false
      g.helper false
      g.assets false
    end

    config.autoload_paths << Rails.root.join('app', 'graph', 'mutations')
    config.autoload_paths << Rails.root.join('app', 'graph', 'types')

    config.autoload_paths << "#{config.root}/app/models/annotations"
    config.autoload_paths << "#{config.root}/app/models/search"
    config.autoload_paths += %W(#{config.root}/lib)

    config.action_mailer.delivery_method = :smtp

    cfg = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

    config.i18n.fallbacks = ['en']
    config.i18n.default_locale = 'en'
    config.i18n.enforce_available_locales = false

    locale = cfg['locale'] || ENV['locale']
    if locale.blank?
      config.i18n.available_locales = ["ar","bn","fil","fr","de","hi","id","kn","ml","mr","pa","pt","ro","ru","es","sw","ta","te","ur","en"] # Do not change manually! Use `rake transifex:languages` instead, or set the `locale` key in your `config/config.yml`
    else
      config.i18n.available_locales = [locale].flatten
    end

    smtp_host = cfg['smtp_host'] || ENV['smtp_host']
    smtp_port = cfg['smtp_port'] || ENV['smtp_port']
    smtp_user = cfg['smtp_user'] || ENV['smtp_user']
    smtp_pass = cfg['smtp_pass'] || ENV['smtp_pass']
    if !smtp_user.blank? && !smtp_pass.blank? && !Rails.env.test?
      config.action_mailer.smtp_settings = {
        address:              smtp_host,
        port:                 smtp_port,
        user_name:            smtp_user,
        password:             smtp_pass,
        authentication:       'plain',
        enable_starttls_auto: true
      }
    end

    allowed_origins = cfg['allowed_origins'] || ENV['allowed_origins']
    authorization_header = cfg['authorization_header'] || ENV['authorization_header']
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins(/^(#{allowed_origins}|(moz|chrome)-extension:)|file:/)
        resource '*',
        credentials: true,
        headers: [authorization_header, 'Content-Type', 'Accept', 'X-Requested-With', 'Origin', 'Access-Control-Request-Method', 'Access-Control-Request-Headers', 'Credentials', 'X-Check-Client', 'X-Check-Team', 'X-API-Key', 'X-Timezone', 'Access-Control-Allow-Credentials'],
        methods: [:get, :post, :put, :delete, :options]
      end
    end

    config.action_dispatch.default_headers.merge!({
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Request-Method' => '*'
    })
  end


end
