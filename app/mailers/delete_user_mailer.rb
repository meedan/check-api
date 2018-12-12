class DeleteUserMailer < ApplicationMailer
  layout nil

  def notify_owners(user, team)
    @user = user
    subject = I18n.t(:mail_subject_delete_user, team: team.name)
    recipients = team.recipients(user, ['owner'])
    self.send_email_to_recipients(recipients, subject, 'delete_user')
  end

  def notify_privacy(user)
    @user = user
    subject = I18n.t(:mail_subject_delete_user, team: CONFIG['app_name'])
    mail(to: CONFIG['privacy_email'], subject: subject)
  end

end
