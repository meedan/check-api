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
    @title = I18n.t("mails_notifications.reset_password.title")
    opts[:subject] = I18n.t('devise.mailer.reset_password_instructions.subject', app_name: CONFIG['app_name'])
    super
  end

  def invitation_instructions(record, token, opts={})
    @host = CONFIG['checkdesk_base_url']
    @client_host = CONFIG['checkdesk_client']
    @team = opts[:invitation_team]
    @role = opts[:role]
    @url = "#{CONFIG['checkdesk_client']}/#{@team.slug}"
    @invited_by = record.invited_by.nil? ? 'Someone' : record.invited_by.name
    @invited_text = opts[:invitation_text]
    @invited_type = @invited_text.blank? ? 'default' : 'custom'
    @due_at = opts[:due_at]
    @title = I18n.t("mails_notifications.invitation.title")
    opts[:subject] = I18n.t(:'devise.mailer.invitation_instructions.subject', user: @invited_by, team: @team.name)
    super
  end
end
