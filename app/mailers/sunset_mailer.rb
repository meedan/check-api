class SunsetMailer < ApplicationMailer
  layout nil

  def notify(email)
    @email = email
    subject = I18n.t("mail_sunset_subject")
    mail(to: email, subject: subject)
  end
end
