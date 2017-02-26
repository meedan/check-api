class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user)
    @user = user
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: I18n.t(:mail_new_account, default: "New account for you on Check"))
  end

  def duplicate_email_detection(user, duplicate)
    @user = user
    @duplicate_provider = duplicate.provider? ? duplicate.provider.camelcase : I18n.t(:mail_duplicate_email_exists_email, default: 'email')
    @user_provider = user.provider? ? user.provider.camelcase : I18n.t(:mail_duplicate_email_exists_email, default: 'email')
    mail(to: @user.email, subject: I18n.t(:mail_duplicate_email_exists, default: "Your login method for Check"))
  end

end
