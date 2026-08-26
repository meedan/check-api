class SunsetMailer < ApplicationMailer
  layout nil

  def notify(type, user, workspace)
    @name = user.name
    # Set subject based on type (notify or download)
    subject_type = type == 'download' ? 'download' : 'notify'
    subject = I18n.t("mail_sunset.#{subject_type}_subject", app_name: CheckConfig.get('app_name'), workspace: workspace)
    @mail_copy = "#{type}_copy"
    @end_date = begin Time.parse(CheckConfig.get('check_sunset_dae')) rescue Time.parse('2027-01-31') end
    @workspace = workspace
    mail(to: user.email, subject: subject)
  end
end
