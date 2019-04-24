class LoginActivity < ActiveRecord::Base
  belongs_to :user, polymorphic: true
  after_create :send_security_notification

  def should_notify?(user, type)
  	return false if user.nil?
  	notify = type == 'success' ? user.settings[:send_successful_login_notifications] : user.settings[:send_failed_login_notifications]
  	notify.nil? || notify
  end

  def get_user
  	user = self.user
  	user = User.where(email: self.identity).last if user.nil?
  	user
  end

  private

  def send_security_notification
		user = get_user
  	if self.success == true
  		send_successfull_login_notification(user) if should_notify?(user, 'success')
  	else
  		send_failed_login_notification(user)if should_notify?(user, 'failed')
  	end
  end

  def send_successfull_login_notification(user)
  	SecurityMailer.delay.notify(user, 'ip', self) if user.last_sign_in_ip_changed?
  	user_agent = user.login_activities.where(success: true).last(2).map(&:user_agent).uniq
  	if user_agent.count > 1
  		SecurityMailer.delay.notify(user, 'device', self)
  	end
  end

  def send_failed_login_notification(user)
    failed_attempts = user.login_activities.where(success: false).count
    if failed_attempts >= CONFIG['failed_attempts']
      SecurityMailer.delay.notify(user, 'failed', self)
      # TODO: Remove failed logins
    end
  end
end
