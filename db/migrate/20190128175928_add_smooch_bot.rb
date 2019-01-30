class AddSmoochBot < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true

    Team.reset_column_information
    User.reset_column_information
    meedan_team = Team.where(slug: 'meedan').last || Team.new(name: 'Meedan', slug: 'meedan')
    meedan_team.skip_notifications = true
    meedan_team.skip_clear_cache = true
    meedan_team.skip_check_ability = true
    meedan_team.save!

    config = CONFIG['clamav_service_path']
    CONFIG['clamav_service_path'] = nil

    tb = TeamBot.new
    tb.identifier = 'smooch'
    tb.name = 'Smooch'
    tb.description = 'A bot that creates items through Smooch.io service.'
    File.open(File.join(Rails.root, 'public', 'smooch.png')) do |f|
      tb.file = f
    end
    tb.request_url = CONFIG['checkdesk_base_url_private'] + '/api/bots/smooch'
    tb.role = 'editor'
    tb.version = '0.0.1'
    tb.source_code_url = 'https://github.com/meedan/check-api/blob/develop/app/models/bot/smooch.rb'
    tb.team_author_id = meedan_team.id
    tb.events = []
    tb.settings = [
      { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
      { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
      { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
      { name: 'smooch_bot_id', label: 'Smooch Bot ID', type: 'string', default: '' },
      { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' },
      { name: 'smooch_window_duration', label: 'Window Duration (in hours - after this time since the last message from the user, the user will be notified... enter 0 to disable)', type: 'number', default: 20 }
    ]
    tb.approved = true
    tb.limited = true
    tb.save!
    
    CONFIG['clamav_service_path'] = config

    RequestStore.store[:skip_notifications] = false
  end
end
