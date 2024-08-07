require 'error_codes'
require 'redis'

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

  config.mailer_sender = CheckConfig.get('default_mail')
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
  config.omniauth :twitter, setup: true
  config.omniauth :facebook, CheckConfig.get('facebook_app_id'), CheckConfig.get('facebook_app_secret'), scope: 'email,public_profile', info_fields: 'name,email,picture', setup: true
  config.omniauth :slack, CheckConfig.get('slack_app_id'), CheckConfig.get('slack_app_secret'), scope: 'identify,users:read'
  google_auth_config = { access_type: 'offline', approval_prompt: '',  provider_ignores_state: true }
  config.omniauth :google_oauth2, CheckConfig.get('google_client_id'), CheckConfig.get('google_client_secret'), google_auth_config
  config.skip_session_storage = [:http_auth, :token_auth]
  config.warden do |manager|
    manager.failure_app = CustomFailure
  end
  config.mailer = 'DeviseMailer'
  config.invite_for = 1.month

  Warden::Manager.after_authentication do |user, auth, opts|
    @redis = Redis.new(REDIS_CONFIG)
    ip = auth.request.ip
    @redis.decr("track:#{ip}")
  end
end

AuthTrail.geocode = false

AuthTrail.exclude_method = lambda do |info|
  (!info[:context].nil? && info[:context].start_with?("api/v1/graphql")) || info[:failure_reason] == 'unconfirmed'
end
