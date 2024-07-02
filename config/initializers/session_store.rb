# Be sure to restart your server when you modify this file.

# We need to allow subdomains to aceess the session cookie so they can auth.
# for Live and QA the session_store_domain should be .checkmedia.org from config file
# TODO: do we need to set seperate cookies for qa and live so the wrong ones don't get posted?
Rails.application.config.session_store :cookie_store, key: '_checkdesk_session', domain: CheckConfig.get('session_store_domain', 'localhost')
