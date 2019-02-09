class AddAlegreBot < ActiveRecord::Migration
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
    tb.identifier = 'alegre'
    tb.name = 'Alegre'
    tb.description = 'A bot that identifies the language of content added to the team.'
    File.open(File.join(Rails.root, 'public', 'alegre.png')) do |f|
      tb.file = f
    end
    tb.request_url = CONFIG['checkdesk_base_url_private'] + '/api/bots/alegre'
    tb.role = 'editor'
    tb.version = '0.0.1'
    tb.source_code_url = 'https://github.com/meedan/check-api/blob/develop/app/models/bot/alegre.rb'
    tb.team_author_id = meedan_team.id
    tb.events = [ { event: 'create_project_media', graphql: 'dbid' } ]
    tb.settings = []
    tb.approved = true
    tb.limited = false
    tb.save!
    
    CONFIG['clamav_service_path'] = config

    RequestStore.store[:skip_notifications] = false
  end
end
