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
    
    cfg = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
    config.action_dispatch.default_headers.merge!({
      'Access-Control-Request-Method' => '*',
      'Access-Control-Allow-Origin' => cfg['checkdesk_client'],
      'Access-Control-Allow-Methods' => 'GET,POST,DELETE,OPTIONS',
      'Access-Control-Allow-Credentials' => 'true'
    })
    config.autoload_paths << Rails.root.join('app', 'graph', 'mutations')
    config.autoload_paths << Rails.root.join('app', 'graph', 'types')
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.autoload_paths << "#{config.root}/app/models/annotations"
    config.autoload_paths += %W(#{config.root}/lib)

    config.action_mailer.delivery_method = :smtp
    
    if !cfg['gmail_username'].blank? && !cfg['gmail_password'].blank? && !Rails.env.test?
      config.action_mailer.smtp_settings = {
        address:              'smtp.gmail.com',
        port:                 587,
        user_name:            cfg['gmail_username'],
        password:             cfg['gmail_password'],
        authentication:       'plain',
        enable_starttls_auto: true
      }
    end
  end
end
