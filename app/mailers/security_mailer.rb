class SecurityMailer < ApplicationMailer
  layout nil

  def notify(user_id, type, activity_id)
    user = User.find_by_id(user_id)
    activity = LoginActivity.find_by_id(activity_id)
    return if user.nil? || activity.nil?
    address = []
    Geocoder.configure(language: I18n.locale)
    ip_result = Geocoder.search(activity.ip)&.first
    unless ip_result.blank? || ip_result.data["loc"].blank?
      loc_result = Geocoder.search(ip_result.data["loc"]).first
      address = [loc_result.city, loc_result.country] unless loc_result.nil?
    end
    @user = user
    @type = type
    email = user.email
    user_agent = UserAgent.parse(activity.user_agent)
    @location = address.compact.join(', ')
    @timestamp = activity.created_at
    @ip = activity.ip
    @platform = begin user_agent.os.split.first rescue 'Unknown' end
    @browser = begin user_agent.browser rescue 'Unknown' end
    subject = I18n.t("mail_security.#{type}_subject",
      app_name: CheckConfig.get('app_name'), browser: @browser, platform: @platform)
    mail(to: email, subject: subject)
  end

  def custom_notification(user_id, subject)
    @user = User.find_by_id(user_id)
    attachments.inline['signup.png'] = File.read('public/images/signup.png')
    mail(to: @user.email, subject: subject)
  end
end
