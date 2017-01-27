class TeamUserMailer < ApplicationMailer
  layout nil

  def request_to_join(team, requestor, origin)
    if team && requestor
      @team = team
      @requestor = requestor
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}/members")
      @handle = requestor.handle
      recipients = team.recipients(requestor)
      self.send_email_to_recipients(recipients, "#{requestor.name} wants to join the #{team.name} team on Check")
    end
  end

  def request_to_join_processed(team, requestor, accepted, origin)
    if team && requestor && !requestor.email.blank?
      @team = team
      @requestor = requestor
      @accepted = accepted
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}")
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      status = accepted ? "accepted" : "rejected"
      self.send_email_to_recipients(requestor.email, "Your request to join #{team.name} on Check was #{status}")
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
