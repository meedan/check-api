# Be sure to restart your server when you modify this file.

# allow subdomains to aceess the session cookie
# TODO: do we need to set seperate cookies for qa and live so the wrong ones don't get posted?
Rails.application.config.session_store :cookie_store, :key => '_checkdesk_session', :domain => '.checkmedia.org'
