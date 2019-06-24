class DeleteUserMailer < ApplicationMailer
  layout nil

  def self.send_notification(user, teams)
    emails = []
    unless CONFIG['privacy_email'].blank?
      subject = I18n.t("mails_notifications.delete_user.subject", team: CONFIG['app_name'])
      self.delay.notify(CONFIG['privacy_email'], user, subject)
      emails << CONFIG['privacy_email']
    end
    teams.each do |team|
      recipients = team.recipients(user, ['owner'])
      recipients = Bounce.remove_bounces(recipients)
      subject = I18n.t("mails_notifications.delete_user.subject", team: team.name)
      recipients.each do |recipient|
        self.delay.notify(recipient, user, subject, 'delete_user')
        emails << recipient
      end
    end
    emails
  end

  def notify(recipient, user, subject, type = nil)
    info = {
      user: user
    }
    self.set_template_var(info, recipient)
    mail(to: recipient, email_type: type, subject: subject)
  end

end
