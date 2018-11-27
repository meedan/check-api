class DeleteUserMailer < ApplicationMailer
  layout nil

  def notify_owners(user)
    @name = I18n.t(:mail_delete_user_anonymous, id: user.id)
    @url = "#{CONFIG['checkdesk_client']}/check/user/#{user.id}"
    user.teams.each do |team|
      subject = I18n.t(:mail_subject_delete_user, team: team.name)
      recipients = team.recipients(user, ['owner'])
      self.send_email_to_recipients(recipients, subject, 'delete_user')
    end
  end

  def notify_privacy(user)
    @name = I18n.t(:mail_delete_user_anonymous, id: user.id)
    @url = "#{CONFIG['checkdesk_client']}/check/user/#{user.id}"
    subject = I18n.t(:mail_subject_delete_user, team: CONFIG['app_name'])
    mail(to: CONFIG['privacy_email'], subject: subject)
  end

end
