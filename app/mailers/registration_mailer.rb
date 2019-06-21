class RegistrationMailer < ApplicationMailer
  layout nil

  def welcome_email(user, password=nil)
    @user = user
    @user.password ||= password
    @url = CONFIG['checkdesk_client']
    mail(to: @user.email, subject: I18n.t("mails_notifications.register.subject", app_name: CONFIG['app_name'])) unless @user.email.blank?
  end

  def duplicate_email_detection(user, provider)
    @user = user
    @duplicate_provider =  provider.blank? ? I18n.t("mails_notifications.duplicated.email") : provider
    @user_provider = user.encrypted_password? ? I18n.t("mails_notifications.duplicated.email") : user.get_user_provider(user.email)
    @body_key = (provider.blank? && user.encrypted_password?) ? "both_emails" : "one_email"
    mail(to: @user.email, subject: I18n.t("mails_notifications.duplicated.subject", app_name: CONFIG['app_name'])) unless @user.email.blank?
  end

end
