class ApplicationMailer < ActionMailer::Base
  default from: CONFIG['default_mail']
  layout 'mailer'

  def self.set_template_direction
    if CheckI18n.is_rtl_lang?
      direction = {
        dir: 'rtl',
        align: 'right',
        arrow: '5DMN6P814LWo5ARRkwIGsU/9b058087aab31c370c9cbf33d4332037/arrow_3x-rtl.png'
      }
    else
      direction = {
         dir: 'ltr',
         align: 'left',
         arrow: '1ji47bOy90143djFnEPuj1/936ebe3388362a7861715a1b819b231b/arrow_3x.png'
       }
    end
    direction
  end

  private

  def mail(options={})
    filter_to_if_user_opted_out(options)
    return if options[:to].blank?
    options[:to] = [options[:to]].flatten.collect{ |to| to.gsub(/[\u200B-\u200D\uFEFF]/, '') }
    @direction = ApplicationMailer.set_template_direction
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
    %w(assignment delete_user task_status)
  end

  def set_template_var(info, email)
    user = User.find_user_by_email(email)
    username = user.nil? ? '' : user.name
    info[:greeting] = I18n.t("mails_notifications.greeting", username: username)
    info[:username] = username
    @info = info
  end

end
