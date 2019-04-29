class LoginActivity < ActiveRecord::Base
  belongs_to :user, polymorphic: true
  after_create :send_security_notification

  def should_notify?(user, type)
  	notify = false
  	return notify if user.nil?
  	if user.is_confirmed?
  		notify = type == 'success' ? user.settings[:send_successful_login_notifications] : user.settings[:send_failed_login_notifications]
  	end
  	notify.nil? || notify
  end

  def get_user
  	user = self.user
  	user = User.find_user_by_email(self.identity) if user.nil?
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
  	activities = user.login_activities.where(success: true).last(2)
  	ip = activities.map(&:ip).uniq
  	if ip.count > 1
  		SecurityMailer.delay.notify(user, 'ip', self)
  	else
  		user_agent = activities.map(&:user_agent).uniq
  		SecurityMailer.delay.notify(user, 'device', self) if user_agent.count > 1
  	end
  end

  def send_failed_login_notification(user)
  	conditions = { success: false }
    last_notification = user.settings[:failed_notifications_time]
    # TODO : add condition for last notification date
    failed_attempts = user.login_activities.where(conditions).count
    if failed_attempts >= CONFIG['failed_attempts']
      SecurityMailer.delay.notify(user, 'failed', self)
      user.settings[:failed_notifications_time] = self.created_at
      user.skip_check_ability = true
      user.save!
    end
  end
end
