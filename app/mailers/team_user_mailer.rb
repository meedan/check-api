class TeamUserMailer < ApplicationMailer
  layout nil

  def request_to_join(team, requestor)
    if team && requestor
      @team = team
      @requestor = requestor
      @url = CONFIG['checkdesk_client'] + '/team/' + team.id.to_s + '/members'
      owners = team.owners
      if !owners.empty? && !owners.include?(@requestor)
        recipients = owners.map(&:email)
        Rails.logger.info "Sending e-mail to #{recipients.join(', ')}"
        mail(to: recipients, subject: "#{requestor.name} wants to join the #{team.name} team on Check")
      end
    end
  end

  def request_to_join_processed(team, requestor, accepted)
    if team && requestor
      @team = team
      @requestor = requestor
      @accepted = accepted
      @url = CONFIG['checkdesk_client'] + '/team/' + team.id.to_s
      
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      status = accepted ? "accepted" : "rejected"
      mail(to: requestor.email, subject: "Your request to join #{team.name} on Check was #{status}")
    end 
  end
end
