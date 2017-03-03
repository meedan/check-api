class TeamUserMailer < ApplicationMailer
  layout nil

  def request_to_join(team, requestor, origin)
    if team && requestor
      @team = team
      @requestor = requestor
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}/members")
      @handle = requestor.handle
      recipients = team.recipients(requestor)
      self.send_email_to_recipients(recipients, I18n.t(:mail_request_to_join, default: "%{user} wants to join %{team} team on Check!", user: requestor.name, team: team.name))
    end
  end

  def request_to_join_processed(team, requestor, accepted, origin)
    if team && requestor && !requestor.email.blank?
      @team = team
      @requestor = requestor
      @accepted = accepted
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}")
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      status = accepted ? I18n.t(:approved, default: "approved!") : I18n.t(:rejected, default: "not approved")
      self.send_email_to_recipients(requestor.email, I18n.t(:mail_request_to_join_processed, default: "Your request to join %{team} on Check was %{status}", team: team.name, status: status))
    end
  end

  protected

  def send_email_to_recipients(recipients, subject)
    recipients = Bounce.remove_bounces(recipients)
    unless recipients.empty?
      Rails.logger.info "Sending e-mail to #{recipients}"
      mail(to: recipients, subject: subject)
    end
  end
end
