# Be sure to restart your server when you modify this file.

# Retrieve the session key name based on the environment using CheckConfig.
# Provide default values specific to each environment.

# Default keys by environment
default_keys = {
  production: '_checkdesk_session',
  development: '_checkdesk_session_dev',
  test: '_checkdesk_session_test'
}

# Get the environment specific session key or default to a predefined value.
cookie_key = CheckConfig.get('session_key', default_keys[Rails.env.to_sym])

# Set the domain for the session cookies based on the environment.
domain_setting = Rails.env.development? ? 'localhost' : '.checkmedia.org'

# Configure the session store with the dynamically obtained session key and domain.
Rails.application.config.session_store :cookie_store, key: cookie_key, domain: domain_setting
