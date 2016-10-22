class TeamUserMailer < ApplicationMailer
  layout nil

  def request_to_join(team, requestor, origin)
    if team && requestor
      @team = team
      @requestor = requestor
      @url = origin.blank? ? '' : URI.join(origin, "/members")
      @handle = requestor.provider.blank? ? requestor.email : "#{requestor.login} at #{requestor.provider.capitalize}"
      owners = team.owners
      if !owners.empty? && !owners.include?(@requestor)
        recipients = owners.map(&:email).reject{ |m| m.blank? }
        unless recipients.empty?
          Rails.logger.info "Sending e-mail to #{recipients.join(', ')}"
          mail(to: recipients, subject: "#{requestor.name} wants to join the #{team.name} team on Check")
        end
      end
    end
  end

  def request_to_join_processed(team, requestor, accepted, origin)
    if team && requestor && !requestor.email.blank?
      @team = team
      @requestor = requestor
      @accepted = accepted
      @url = origin.blank? ? '' : URI.join(origin, "/")
      Rails.logger.info "Sending e-mail to #{requestor.email}"
      status = accepted ? "accepted" : "rejected"
      mail(to: requestor.email, subject: "Your request to join #{team.name} on Check was #{status}")
    end
  end
end
