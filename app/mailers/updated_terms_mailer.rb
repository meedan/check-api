class UpdatedTermsMailer < ApplicationMailer
  layout nil

  def notify(recipient, name)
    @name = name
    @accept_terms_url = CheckConfig.get('tos_url')
    subject = I18n.t("mails_notifications.updated_terms.subject")
    Rails.logger.info "Sending ToS e-mail to #{recipient}"
    begin
      mail(to: recipient, email_type: 'updated_terms', subject: subject)
    rescue Net::SMTPFatalError
      nil
    end
  end
end
