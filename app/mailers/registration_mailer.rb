class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user, password=nil)
    @user = user
    @user.password ||= password
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: I18n.t(:mail_new_account, app_name: CONFIG['app_name'])) unless @user.email.blank?
  end

  def duplicate_email_detection(user, provider)
    @user = user
    @duplicate_provider =  provider.blank? ? I18n.t(:mail_duplicate_email_exists_email) : provider
    @user_provider = user.encrypted_password? ? I18n.t(:mail_duplicate_email_exists_email) : user.get_user_provider(user.email)
    @mail_body = (provider.blank? && user.encrypted_password?) ? :mail_duplicate_email_exists_body_both_emails : :mail_duplicate_email_exists_body
    mail(to: @user.email, subject: I18n.t(:mail_duplicate_email_exists, app_name: CONFIG['app_name'])) unless @user.email.blank?
  end

end
