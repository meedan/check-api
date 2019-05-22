class ApplicationMailer < ActionMailer::Base
  default from: CONFIG['default_mail']
  layout 'mailer'

  private

  def mail(options={})
    filter_to_if_user_opted_out(options)
    return if options[:to].empty?
    super(options)
  end

  def filter_to_if_user_opted_out(options)
    return unless opted_out_types.include?(options[:email_type])

    users = User.where(email: options[:to]).to_a
    users.delete_if {|u| u.get_send_email_notifications == false || !u.is_active? }
    options[:to] = users.blank? ? [] : users.map(&:email)
  end

  protected

  def send_email_to_recipients(recipients, subject, type=nil)
    recipients = Bounce.remove_bounces(recipients)
    unless recipients.empty?
      Rails.logger.info "Sending e-mail to #{recipients}"
      mail(to: recipients, email_type: type, subject: subject)
    end
  end

  def opted_out_types
    %w(assignment terminal_status delete_user task_status)
  end
end
