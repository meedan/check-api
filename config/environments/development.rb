require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Same cache store as production
  file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
  file = File.join(Rails.root, 'config', "sidekiq.yml") unless File.exist?(file)
  if File.exist?(file)
    require 'sidekiq/middleware/i18n'
    redis_config = YAML.load_file(file)
    redis_url = { host: redis_config[:redis_host], port: redis_config[:redis_port], db: redis_config[:redis_database], namespace: "cache_checkapi_#{Rails.env}" }
    config.cache_store = :redis_cache_store, redis_url
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.allow_concurrency = true

  config.log_level = :debug

  config.action_mailer.default_url_options = { host: 'http://localhost:3000' }

  cfg = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
  if cfg['whitelisted_hosts']
    config.hosts.concat(cfg['whitelisted_hosts'].split(','))
  else
    puts '[WARNING] config.hosts not provided. Only requests from localhost are allowed. To change, update `whitelisted_hosts` in config.yml'
  end
end
