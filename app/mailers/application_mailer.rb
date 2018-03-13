class ApplicationMailer < ActionMailer::Base
  default from: CONFIG['default_mail']
  layout 'mailer'

  protected

  def send_email_to_recipients(recipients, subject)
    recipients = Bounce.remove_bounces(recipients)
    unless recipients.empty?
      Rails.logger.info "Sending e-mail to #{recipients}"
      mail(to: recipients, subject: subject)
    end
  end
  
end
