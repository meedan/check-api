class ExportListMailer < ApplicationMailer
  layout nil

  def send_csv(csv_file_url, user)
    @csv_file_url = csv_file_url
    @user = user
    @expire_in = CheckConfig.get('export_csv_expire', 7.days.to_i, :integer) / (60 * 60 * 24)
    subject = I18n.t('mails_notifications.export_list.subject')
    Rails.logger.info "Sending export e-mail to #{@user.email}"
    mail(to: @user.email, email_type: 'export_list', subject: subject)
  end
end
