class LoginActivity < ApplicationRecord
  belongs_to :user, polymorphic: true, optional: true
  after_create :send_security_notification
  before_create :set_original_ip

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

  def set_original_ip
    unless RequestStore[:request].blank?
      original_ip = RequestStore[:request].headers['X-Forwarded-For'].to_s
      self.ip = original_ip.split(',').first unless original_ip.blank?
    end
  end

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
      SecurityMailer.delay.notify(user.id, 'ip', self.id)
    else
      user_agent = activities.map(&:user_agent).uniq
      SecurityMailer.delay.notify(user.id, 'device', self.id) if user_agent.count > 1
    end
  end

  def send_failed_login_notification(user)
    last_notification = user.settings[:failed_notifications_time]
    if last_notification.nil?
      failed_attempts = LoginActivity.where(identity: self.identity, success: false).count
    else
      failed_attempts = LoginActivity.where('identity = ? AND success = ? AND created_at > ?', self.identity, false, last_notification).count
    end
    if failed_attempts >= CheckConfig.get('failed_attempts', 4).to_i
      SecurityMailer.delay.notify(user.id, 'failed', self.id)
      user.set_failed_notifications_time = self.created_at
      user.skip_check_ability = true
      user.save!
    end
  end
end
