class SecurityMailer < ApplicationMailer
	layout nil

  def notify(user, type, activity)
    address = []
    Geocoder.configure(language: I18n.locale)
    ip_result = Geocoder.search(activity.ip).first
    unless ip_result.blank? || ip_result.data["loc"].blank?
      loc_result = Geocoder.search(ip_result.data["loc"]).first
      address = [loc_result.city, loc_result.country]
    end
  	@user = user
  	@type = type
  	email = user.email
  	@user_agent = UserAgent.parse(activity.user_agent)
    @location = address.compact.join(', ')
  	@timestamp = activity.created_at.strftime('%A, %d %B %Y %I:%M %p %Z')
  	@ip = activity.ip
    @platform = @user_agent.os.split.first
  	subject = I18n.t("mail_security.#{type}_subject",
      app_name: CONFIG['app_name'], browser: @user_agent.browser, platform: @platform)
    mail(to: email, subject: subject)
  end

end
