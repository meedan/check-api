class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  layout nil

  def confirmation_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    @client_host = CONFIG['checkdesk_client']
    opts[:subject] = I18n.t(:mail_account_confirmation, default: "%{product_name} account confirmation", product_name: CONFIG['product_name'])
    super
  end

  def reset_password_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    opts[:subject] = I18n.t(:reset_password_instructions, default: "%{product_name} reset password instructions", product_name: CONFIG['product_name'])
    super
  end
end
