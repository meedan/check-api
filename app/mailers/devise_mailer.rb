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
    @invited_by = record.invited_by.nil? ? 'Someone' : record.invited_by.name
    @invited_text = record.invitation_text
    @invited_type = @invited_text.nil? ? 'default' : 'custom'
    opts[:subject] = I18n.t(:'devise.mailer.invitation_instructions.subject', user: @invited_by, team: Team.current.name)
    super
  end
end
