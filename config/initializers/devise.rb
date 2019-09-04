require 'error_codes'

class CustomFailure < Devise::FailureApp
  def respond
    http_auth
  end

  protected

  def http_auth_body
    {
      errors: [{
        message: i18n_message,
        code: LapisConstants::ErrorCodes::const_get('UNAUTHORIZED'),
        data: {},
      }],
    }.to_json
  end

end

OmniAuth.config.logger = Rails.logger

Devise.setup do |config|
  config.warden do |manager|
    manager.default_strategies(:scope => :user).unshift :two_factor_authenticatable
    manager.default_strategies(:scope => :user).unshift :two_factor_backupable
  end

  config.mailer_sender = CONFIG['default_mail']
  require 'devise/orm/active_record'
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 10
  config.reconfirmable = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_in_after_reset_password = false
  config.sign_out_via = :delete
  config.omniauth :twitter, CONFIG['twitter_consumer_key'], CONFIG['twitter_consumer_secret']
  config.omniauth :facebook, CONFIG['facebook_app_id'], CONFIG['facebook_app_secret'], scope: 'email,public_profile', info_fields: 'name,email,picture'
  config.omniauth :slack, CONFIG['slack_app_id'], CONFIG['slack_app_secret'], scope: 'identify,users:read'
  google_auth_config = { access_type: 'offline', approval_prompt: '' }
  google_auth_config[:redirect_uri] = CONFIG['google_auth_redirect_uri'] unless CONFIG['google_auth_redirect_uri'].blank?
  config.omniauth :google_oauth2, CONFIG['google_client_id'], CONFIG['google_client_secret'], google_auth_config
  config.skip_session_storage = [:http_auth, :token_auth]
  config.warden do |manager|
    manager.failure_app = CustomFailure
  end
  config.mailer = 'DeviseMailer'
  config.invite_for = 1.day
end

AuthTrail.geocode = false

AuthTrail.exclude_method = lambda do |info|
  info[:context] == "api/v1/graphql#create" || info[:failure_reason] == 'unconfirmed'
end
