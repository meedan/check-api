class SecurityMailer < ApplicationMailer
	layout nil

  def notify(user, type, activity)
    # Getting location
    AuthTrail::GeocodeJob.perform_now(activity)
    activity = activity.reload
  	@user = user
  	@type = type
  	email = user.email
  	@user_agent = UserAgent.parse(activity.user_agent)
  	@location = "#{activity.city}, #{activity.country}"
  	@timestamp = activity.created_at.strftime('%A, %d %B %Y %I:%M %p %Z')
  	@ip = activity.ip
  	subject = I18n.t("mail_security.#{type}_subject",
      app_name: CONFIG['app_name'], browser: @user_agent.browser, platform: @user_agent.platform)
    mail(to: email, subject: subject)
  end

end
