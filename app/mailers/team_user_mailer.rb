class TeamUserMailer < ApplicationMailer
  layout nil

  def self.send_notification(options)
    options = YAML::load(options)
    team = options[:team]
    requestor = options[:user]
    if team && requestor
      info = {
        team: team,
        requestor: requestor,
        url: "#{CONFIG['checkdesk_client']}/#{team.slug}",
        handle: requestor.handle,
      }
      subject = I18n.t("mails_notifications.request_to_join.subject", team: team.name)
      recipients = team.recipients(requestor)
      recipients = Bounce.remove_bounces(recipients)
      recipients.each do |recipient|
        request_to_join(recipient, info, subject).deliver_now
      end
    end
  end

  def request_to_join(recipient, info, subject)
    self.set_template_var(info, recipient)
    mail(to: recipient, subject: subject)
  end

  def request_to_join_processed(team, requestor, accepted)
    if team && requestor && !requestor.email.blank?
      request_status = accepted ? 'approved' : 'rejected'
      info = {
        team: team,
        requestor: requestor,
        url: "#{CONFIG['checkdesk_client']}/#{team.slug}",
        request_status: request_status
      }
      self.set_template_var(info, requestor.email)
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      subject = I18n.t("mails_notifications.request_to_join.#{request_status}_subject", team: team.name)
      self.send_email_to_recipients(requestor.email, subject)
    end
  end

end
