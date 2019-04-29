class SecurityMailer < ApplicationMailer
	layout nil

  def notify(user, type, activity)
  	@user = user
  	@type = type
  	email = user.email
  	@user_agent = UserAgent.parse(activity.user_agent)
  	@location = "#{activity.region}, #{activity.country}"
  	@timestamp = activity.created_at
  	@ip = activity.ip
  	subject = I18n.t("mail_security.subject")
    mail(to: email, subject: subject)
  end

end
