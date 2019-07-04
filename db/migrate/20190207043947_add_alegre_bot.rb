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

    Team.current = meedan_team
    tb = BotUser.new
    tb.login = 'alegre'
    tb.name = 'Alegre'
    tb.set_description 'A bot that identifies the language of content added to the team.'
    File.open(File.join(Rails.root, 'public', 'alegre.png')) do |f|
      tb.image = f
    end
    tb.set_request_url CONFIG['checkdesk_base_url_private'] + '/api/bots/alegre'
    tb.set_role 'editor'
    tb.set_version '0.0.1'
    tb.set_source_code_url 'https://github.com/meedan/check-api/blob/develop/app/models/bot/alegre.rb'
    tb.set_team_author_id meedan_team.id
    tb.set_events [ { event: 'create_project_media', graphql: 'dbid' } ]
    tb.set_settings []
    tb.set_approved true
    tb.set_limited true
    tb.save!
    Team.current = nil
    
    CONFIG['clamav_service_path'] = config

    RequestStore.store[:skip_notifications] = false
  end
end
