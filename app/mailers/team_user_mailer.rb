class TeamUserMailer < ApplicationMailer
  layout nil

  def request_to_join(team, requestor, origin)
    if team && requestor
      @team = team
      @requestor = requestor
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}")
      @handle = requestor.handle
      recipients = team.recipients(requestor)
      self.send_email_to_recipients(recipients, I18n.t(:mail_request_to_join, user: requestor.name, team: team.name, app_name: CONFIG['app_name']))
    end
  end

  def request_to_join_processed(team, requestor, accepted, origin)
    if team && requestor && !requestor.email.blank?
      @team = team
      @requestor = requestor
      @accepted = accepted
      @url = origin.blank? ? '' : URI.join(origin, "/#{@team.slug}")
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      status = accepted ? I18n.t(:approved) : I18n.t(:rejected)
      self.send_email_to_recipients(requestor.email,
      I18n.t(:mail_request_to_join_processed, team: team.name, status: status, app_name: CONFIG['app_name']))
    end
  end

end
