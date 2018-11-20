class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user, password=nil)
    @user = user
    @user.password ||= password
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: I18n.t(:mail_new_account, app_name: CONFIG['app_name']))
  end

  def duplicate_email_detection(user, duplicate)
    @user = user
    @duplicate_provider = duplicate.provider? ? duplicate.provider.camelcase : I18n.t(:mail_duplicate_email_exists_email)
    @user_provider = user.provider? ? user.provider.camelcase : I18n.t(:mail_duplicate_email_exists_email)
    @mail_body = (duplicate.provider? || user.provider?) ? :mail_duplicate_email_exists_body : :mail_duplicate_email_exists_body_both_emails
    mail(to: @user.email, subject: I18n.t(:mail_duplicate_email_exists, app_name: CONFIG['app_name']))
  end

end
