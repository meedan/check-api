class SunsetMailer < ApplicationMailer
  layout nil

  def notify(user, workspace)
    @name = user.name
    subject = I18n.t("mail_sunset_subject")
    subject = I18n.t("mail_sunset.subject", app_name: CheckConfig.get('app_name'), workspace: workspace)
    mail(to: user.email, subject: subject)
  end
end
