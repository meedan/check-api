# Be sure to restart your server when you modify this file.

# Retrieve the session key and domain based on the environment using CheckConfig.
cookie_key = CheckConfig.get('session_store_key', '_checkdesk_session')
domain_setting = CheckConfig.get('session_store_domain', Rails.env.development? ? 'localhost' : '.checkmedia.org')

# Configure the session store with the dynamically obtained session key and domain.
Rails.application.config.session_store :cookie_store, key: cookie_key, domain: domain_setting
