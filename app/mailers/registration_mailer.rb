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
    @duplicate_provider = duplicate.encrypted_password? ? I18n.t(:mail_duplicate_email_exists_email) : duplicate.get_social_accounts_for_login.first.provider
    @user_provider = user.encrypted_password? ? I18n.t(:mail_duplicate_email_exists_email) : user.get_social_accounts_for_login.first.provider
    @mail_body = (duplicate.encrypted_password? && user.encrypted_password?) ? :mail_duplicate_email_exists_body_both_emails : :mail_duplicate_email_exists_body
    mail(to: @user.email, subject: I18n.t(:mail_duplicate_email_exists, app_name: CONFIG['app_name']))
  end

end
