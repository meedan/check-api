class SunsetMailer < ApplicationMailer
  layout nil

  def notify(type, user, workspace, workspace_url)
    @name = user.name
    # Set subject based on type (notify or download)
    subject_type = type == 'download' ? 'download' : 'notify'
    subject = I18n.t("mail_sunset.#{subject_type}_subject", app_name: CheckConfig.get('app_name'), workspace: workspace)
    # Dates for low usage workspaces
    low_usage_end_date = begin Time.parse(CheckConfig.get('check_sunset_low_usage_date')) rescue Time.parse('2026-11-03') end
    low_usage_download_link_date = begin Time.parse(CheckConfig.get('check_sunset_low_usage_download_link_date')) rescue Time.parse('2026-11-04') end
    # Dates for high usage workspaces
    high_usage_end_date = begin Time.parse(CheckConfig.get('check_sunset_high_usage_date')) rescue Time.parse('2027-01-31') end
    @info = {
      mail_copy: "#{type}_copy",
      high_usage_end_date: high_usage_end_date,
      low_usage_end_date: low_usage_end_date,
      low_usage_download_link_date: low_usage_download_link_date,
      workspace: workspace,
      workspace_url: workspace_url,
      download_expire_days: CheckConfig.get('check_sunset_download_expire_days', 14, :integer),
      download_expire_extended_days: CheckConfig.get('check_sunset_download_expire_extended_days', 10, :integer),
    }
    @workspace = workspace
    @workspace_url = workspace_url
    mail(to: user.email, subject: subject)
  end
end
