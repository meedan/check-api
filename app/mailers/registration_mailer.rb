class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user)
    @user = user
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: I18n.t(:mail_new_account, default: "New account for you on Check"))
  end

  def duplicate_email_detection(user, duplicate)
    @user = user
    @provider = duplicate.provider? ? "#{duplicate.provider.camelcase}" : 'email'
    @provider_prefix = duplicate.provider? ? 'a' : 'an'
    @login_with = user.provider? ? "a #{user.provider.camelcase} account linked to" : 'an email-based account using'
    mail(to: @user.email, subject: I18n.t(:mail_duplicate_email_exists, default: "Your Login Method for Check"))
  end

end
