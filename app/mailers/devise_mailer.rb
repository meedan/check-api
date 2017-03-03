class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  layout nil

  def confirmation_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    @client_host = CONFIG['checkdesk_client']
    opts[:subject] = I18n.t(:mail_account_confirmation, default: "Check account confirmation")
    super
  end
end
