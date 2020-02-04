require 'ougai'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.perform_deliveries = false
  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Whitelist docker access
  config.web_console.whitelisted_ips = '172.0.0.0/8'

  # http://guides.rubyonrails.org/caching_with_rails.html#configuration
  # config.cache_store = :memory_store, { size: 64.megabytes }
  file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
  file = File.join(Rails.root, 'config', "sidekiq.yml") unless File.exist?(file)
  if File.exist?(file)
    require 'sidekiq/middleware/i18n'
    redis_config = YAML.load_file(file)
    redis_url = { host: redis_config[:redis_host], port: redis_config[:redis_port], db: redis_config[:redis_database], namespace: "cache_checkapi_#{Rails.env}" }
    config.cache_store = :redis_store, redis_url
  end

  config.allow_concurrency = true

  config.action_mailer.default_url_options = { host: 'http://localhost:3000' }

  config.logger = OugaiLogger::Logger.new(STDOUT)
end
