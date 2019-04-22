class SecurityMailer < ApplicationMailer
	layout nil

  def notify(user, type)
  	@user = user
  	@type = type
  	email = user.email
  	subject = I18n.t(:mail_subject_security_alert)
    mail(to: email, subject: subject)
  end

end
