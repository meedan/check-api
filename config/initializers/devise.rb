require 'error_codes'

class CustomFailure < Devise::FailureApp
  def respond
    http_auth
  end
end

Devise.setup do |config|
  config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
  require 'devise/orm/active_record'
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.omniauth :twitter, CONFIG['twitter_consumer_key'], CONFIG['twitter_consumer_secret']
  config.omniauth :facebook, CONFIG['facebook_app_id'], CONFIG['facebook_app_secret'], scope: 'email,publish_actions,public_profile', info_fields: 'name,email,picture,link'
  config.omniauth :slack, CONFIG['slack_app_id'], CONFIG['slack_app_secret'], scope: 'identity.basic'
  config.skip_session_storage = [:http_auth, :token_auth]
  config.warden do |manager|
    manager.failure_app = CustomFailure
  end
end
