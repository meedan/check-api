class AdminMailer < ApplicationMailer
  layout nil
    
  def send_download_link(obj, email, password)
    if obj.is_a?(Project)
      link = obj.csv_filepath.gsub(/^.*\/public/, CONFIG['checkdesk_base_url'])
      Rails.logger.info "Sending e-mail to #{email} with download link #{link} related to project #{obj.title}"
      @project = obj.title
      @link = link
      @days = CONFIG['export_download_expiration_days'].to_s
      @app = CONFIG['app_name']
      @password = password
      mail(to: email, subject: I18n.t(:project_export_email_title))
    end
  end
end
