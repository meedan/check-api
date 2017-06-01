class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  layout nil

  def confirmation_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    @client_host = CONFIG['checkdesk_client']
    opts[:subject] = I18n.t(:mail_account_confirmation, app_name: CONFIG['app_name'])
    super
  end

  def reset_password_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    opts[:subject] = I18n.t(:reset_password_instructions, app_name: CONFIG['app_name'])
    super
  end
end
