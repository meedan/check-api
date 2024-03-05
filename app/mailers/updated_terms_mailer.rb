class UpdatedTermsMailer < ApplicationMailer
  layout nil

  def notify(recipient, name)
    @name = name
    @accept_terms_url = "#{CheckConfig.get('checkdesk_client')}/check/updated-terms-url"
    subject = I18n.t("mails_notifications.updated_terms.subject")
    Rails.logger.info "Sending ToS e-mail to #{recipient}"
    mail(to: recipient, email_type: 'updated_terms', subject: subject)
  end
end
