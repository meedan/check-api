  class SunsetMailer < ApplicationMailer
  layout nil

  def notify(type, user_id, team_id)
    user = User.find_by_id user_id
    team = Team.find_by_id team_id
    if team && user
      @name = user.name
      workspace = team.name
      workspace_url = team.url
      # Set subject based on type (notify or download)
      if type == 'download'
        subject = "#{CheckConfig.get('app_name')} exported data for #{workspace} workspace is ready to download"
      elsif type == 'notify_low_usage'
        subject = "Housekeeping update for inactive #{CheckConfig.get('app_name')} workspaces (#{workspace})"
      elsif type == 'notify_high_usage'
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

  def request_export_notification(export_id)
    de = CheckDataExport.find_by_id export_id
    unless de.nil?
      team = de.team
      requestor = de.user
      @info = {
        workspace: team.name,
        workspace_url: team.url,
        requestor_name: requestor.name,
        requestor_email: requestor.email,
        url: "#{CheckConfig.get('checkdesk_client')}/#{team.slug}",
        requested_on: de.created_at.strftime("%Y-%m-%d"),
      }
      subject = "Check Sunset: Workspace Data Export Requested (#{team.name})"
      mail(to: CheckConfig.get('support_email'), subject: subject)
    end
  end
end
