class SecurityMailer < ApplicationMailer
	layout nil

  def notify(user, type, activity)
  	@user = user
  	@type = type
  	email = user.email
  	@user_agent = UserAgent.parse(activity.user_agent)
  	@location = activity.ip
  	@timestamp = activity.created_at
  	subject = I18n.t(:mail_subject_security_alert)
    mail(to: email, subject: subject)
  end

end
