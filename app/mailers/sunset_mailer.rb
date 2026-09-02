class SunsetMailer < ApplicationMailer
  layout nil

  def notify(type, user, workspace, workspace_url)
    @name = user.name
    # Set subject based on type (notify or download)
    if type == 'download'
      subject = "#{CheckConfig.get('app_name')} exported data for #{workspace} workspace is ready to download"
    elsif type == 'notify_low_usage'
      subject = "Housekeeping update for inactive #{CheckConfig.get('app_name')} workspaces (#{workspace})"
    else
      subject = "Sunset alert: #{CheckConfig.get('app_name')} sunset for #{workspace} workspace"
    end
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
      download_expire_days: CheckConfig.get('check_sunset_download_expire_days', 15, :integer),
      download_expire_extended_days: CheckConfig.get('check_sunset_download_expire_extended_days', 10, :integer),
    }
    mail(to: user.email, subject: subject)
  end
end
