class AdminMailer < ApplicationMailer
  layout nil

  def notify_import_completed(email, worksheet_url)
    return if email.blank?
    Rails.logger.info "[Data Import/Export] Sending e-mail to #{email} to inform that the data import of #{worksheet_url} has completed"
    @worksheet_url = worksheet_url
    mail(to: email, subject: I18n.t("mails_notifications.admin_mailer.team_import_subject"))
  end

end
