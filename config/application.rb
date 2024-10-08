require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Check
  class Application < Rails::Application
    config.load_defaults 5.2

    # Enable below once we're ready to move to Zeitwork autoloader introduced in Rails 6.0
    # config.autoloader = :zeitwerk

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

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

    # i18n
    config.i18n.fallbacks = ['en']
    config.i18n.default_locale = 'en'
    config.i18n.enforce_available_locales = false

    locale = ENV['locale'] || cfg['locale']
    if locale.blank?
      config.i18n.available_locales = ["ar","bho","bn","ckb","fil","fr","de","hi","id","it","kn","mk","ml","mn","mr","pa","pt","ro","ru","es","sw","ta","te","uk","ur","en","am","as","bn_BD","gu","ks","ne","si","tl"] # Do not change manually! Use `rake transifex:languages` instead, or set the `locale` key in your `config/config.yml`
    else
      config.i18n.available_locales = [locale].flatten
    end

    # Cache configuration
    sidekiq_config_for_env = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
    sidekiq_config = File.exist?(sidekiq_config_for_env) ? sidekiq_config_for_env : File.join(Rails.root, 'config', "sidekiq.yml")

    if File.exist?(sidekiq_config) && !Rails.env.test?
      require 'sidekiq/middleware/i18n'
      redis_config = YAML.load_file(sidekiq_config)
      redis_url = { host: redis_config[:redis_host], port: redis_config[:redis_port], db: redis_config[:redis_database], namespace: "cache_checkapi_#{Rails.env}" }
      config.cache_store = :redis_cache_store, redis_url
    end

    # actionmailer config
    smtp_host = ENV['smtp_host'] || cfg['smtp_host']
    smtp_port = ENV['smtp_port'] || cfg['smtp_port']
    smtp_user = ENV['smtp_user'] || cfg['smtp_user']
    smtp_pass = ENV['smtp_pass'] || cfg['smtp_pass']
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
    config.action_mailer.default_url_options = { host: ENV['smtp_default_url_host'] || cfg['smtp_default_url_host'] }

    # CORS config
    allowed_origins = ENV['allowed_origins'] || cfg['allowed_origins']
    authorization_header = ENV['authorization_header'] || cfg['authorization_header']
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

    config.active_record.yaml_column_permitted_classes = [Time, Symbol]

    # Rack Attack Configuration
    config.middleware.use Rack::Attack
  end
end
