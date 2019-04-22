require 'error_codes'

class CustomFailure < Devise::FailureApp
  def respond
    http_auth
  end
end

Devise.setup do |config|
  config.mailer_sender = CONFIG['default_mail']
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
  config.omniauth :facebook, CONFIG['facebook_app_id'], CONFIG['facebook_app_secret'], scope: 'email,public_profile', info_fields: 'name,email,picture'
  config.omniauth :slack, CONFIG['slack_app_id'], CONFIG['slack_app_secret'], scope: 'identify,users:read'
  config.skip_session_storage = [:http_auth, :token_auth]
  config.warden do |manager|
    manager.failure_app = CustomFailure
  end
  config.mailer = 'DeviseMailer'
  config.invite_for = 1.day
end

Warden::Manager.after_authentication do |user, auth, opts|
  notify = user.settings[:send_successful_login_notifications]
  if notify.nil? || notify
    SecurityMailer.delay.notify(user, 'ip') if user.last_sign_in_ip_changed?
  end
end

Warden::Manager.before_failure do |env, opts|
  Rails.logger.info "LogBeforeFailer #{env["action_dispatch.request.request_parameters"].inspect}"
  Rails.logger.info "LogBeforeFailer - ops #{opts[:action].inspect}"
  if opts[:action] == "unauthenticated"
    request_parameters = env["action_dispatch.request.request_parameters"]
    email = request_parameters[:api_user] && request_parameters[:api_user][:email]
    user = User.where(email: email).last
    unless user.nil?
      notify = user.settings[:send_failed_login_notifications]
      if notify.nil? || notify
        failed_attempts = user.settings[:failed_attempts].nil? ? 1 : user.settings[:failed_attempts] + 1
        if failed_attempts >= CONFIG['failed_attempts']
          user.set_failed_attempts = 0
          user.skip_check_ability = true
          user.save!
          SecurityMailer.delay.notify(user, 'failed')
        end
      end 
    end
  end

end