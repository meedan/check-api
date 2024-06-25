# Be sure to restart your server when you modify this file.

# allow subdomains to aceess the session cookie
# :domain => :all tells Rails to put a dot in front of the cookie domain (which is whatever host your browser has
# browsed to), such that the cookie applies to all subdomains.
# TODO: do we need to set seperate cookies for qa and live so the wrong ones don't get posted?
if Rails.env.production?
  Rails.application.config.session_store :cookie_store, key: '_checkdesk_session', domain: '.checkmedia.org'
elsif Rails.env.development?
  Rails.application.config.session_store :cookie_store, key: '_checkdesk_session', domain: 'localhost'
else
  Rails.application.config.session_store :cookie_store, key: '_checkdesk_session'
end
