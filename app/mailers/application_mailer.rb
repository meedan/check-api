class ApplicationMailer < ActionMailer::Base
  default from: CONFIG['default_mail']
  layout 'mailer'

  after_action :prevent_delivery

  private

  def prevent_delivery
    u = User.where(email: mail.to.first).last # TODO: Review this part for multiple emails
    mail.perform_deliveries = false if !u.nil? && u.get_send_email_notifications == "0"
  end
end
