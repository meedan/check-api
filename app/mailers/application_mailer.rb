class ApplicationMailer < ActionMailer::Base
  default from: CONFIG['default_mail']
  layout 'mailer'

  after_action :prevent_delivery

  private

  def prevent_delivery
    u = User.where(email: mail.to.first).last unless mail.to.blank? # TODO: Review this part for multiple emails
    mail.perform_deliveries = false if !u.nil? && u.get_send_email_notifications == "0"
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
