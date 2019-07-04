class AddKeepBot < ActiveRecord::Migration
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
    tb.login = 'keep'
    tb.name = 'Keep'
    tb.set_description 'A bot that archives links to several archiving services.'
    File.open(File.join(Rails.root, 'public', 'keep.png')) do |f|
      tb.image = f
    end
    tb.set_request_url CONFIG['checkdesk_base_url_private'] + '/api/bots/keep'
    tb.set_role 'editor'
    tb.set_version '0.0.1'
    tb.set_source_code_url 'https://github.com/meedan/check-api/blob/develop/app/models/bot/keep.rb'
    tb.set_team_author_id meedan_team.id
    tb.set_events [ { event: 'create_project_media', graphql: 'dbid' } ]
    tb.set_approved true
    tb.set_limited true
    tb.save!
    Team.current = nil
    
    CONFIG['clamav_service_path'] = config

    Team.find_each do |team|
      unless team.limits.select{ |key, value| ['keep_screenshot', 'keep_archive_is', 'keep_video_vault'].include?(key.to_s) && value.to_i == 1 }.empty?
        team.set_limits_keep = true
        team.skip_notifications = true
        team.skip_clear_cache = true
        team.skip_check_ability = true
        team.save(validate: false)
      end

      team = Team.find(team.id)

      unless team.settings.select{ |key, value| key.to_s =~ /^archive_.*_enabled/ && value.to_i == 1 }.empty?
        tb.install_to!(team) if team.get_limits_keep
      end
    end
    
    RequestStore.store[:skip_notifications] = false
  end
end
