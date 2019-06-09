class DeleteUserMailer < ApplicationMailer
  layout nil

  def self.send_owner_notification(user, team)
    recipients = team.recipients(user, ['owner'])
    recipients = Bounce.remove_bounces(recipients)
    subject = I18n.t(:mail_subject_delete_user, team: team.name)
    recipients.each do |recipient|
      self.delay.notify_owners(recipient, user, subject)
    end
  end

  def notify_owners(recipient, user, subject)
    @user = user
    mail(to: recipient, email_type: 'delete_user', subject: subject)
  end

  def notify_privacy(user)
    email = CONFIG['privacy_email']
    return if email.blank?
    @user = user
    subject = I18n.t(:mail_subject_delete_user, team: CONFIG['app_name'])
    mail(to: email, subject: subject)
  end

end
