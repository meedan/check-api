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

  def invitation_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    @client_host = CONFIG['checkdesk_client']
    @url = "#{CONFIG['checkdesk_client']}/#{Team.current.slug}"
    user = record.invited_by.nil? ? 'Someone' : record.invited_by.name
    opts[:subject] = I18n.t(:'devise.mailer.invitation_instructions.subject', user: user, team: Team.current.name)
    super
  end
end
