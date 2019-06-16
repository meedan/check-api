class AdminMailer < ApplicationMailer
  layout nil
    
  def send_download_link(type, obj, email, password)
    if obj.is_a?(Project)
      return unless !email.blank?
      link = obj.export_filepath(type).gsub(/^.*\/public/, CONFIG['checkdesk_base_url'])
      Rails.logger.info "Sending e-mail to #{email} with download link #{link} related to project #{obj.title}"
      @project = obj.title
      @link = link
      @days = CONFIG['export_download_expiration_days'] || 7
      @password = password
      @type = type
      recipients = obj.team.owners('owner', ['member']).where.not(email: [nil, '', email]).to_a
      recipients = recipients.delete_if {|u| u.get_send_email_notifications == false }.map(&:email)
      recipients = Bounce.remove_bounces(recipients)
      subject = I18n.t("mails_notifications.admin_mailer.project_export_#{type}_subject", project: @project)
      mail(to: email, cc: recipients, subject: subject)
    end
  end

  def notify_import_completed(email, worksheet_url)
    return if email.blank?
    Rails.logger.info "[Team Import] Sending e-mail to #{email} to inform that the data import of #{worksheet_url} has completed"
    @worksheet_url = worksheet_url
    mail(to: email, subject: I18n.t("mails_notifications.admin_mailer.team_import_subject"))
  end

  def send_team_download_link(slug, link, email, password)
    @link = link.gsub(/^.*\/public/, CONFIG['checkdesk_base_url'])
    Rails.logger.info "Sending e-mail to #{email} with download link #{@link} related to team #{slug}"
    @team = slug
    @days = CONFIG['export_download_expiration_days'] || 7
    @password = password
    mail(to: email, subject: I18n.t("mails_notifications.admin_mailer.team_download_subject", team: @team))
  end

end
