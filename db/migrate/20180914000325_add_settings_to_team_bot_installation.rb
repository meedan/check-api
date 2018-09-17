class AddSettingsToTeamBotInstallation < ActiveRecord::Migration
  def change
    config = CONFIG['clamav_service_path']
    CONFIG['clamav_service_path'] = nil

    add_column :team_bots, :settings, :text
    add_column :team_bot_installations, :settings, :text
    
    TeamBot.reset_column_information
    TeamBotInstallation.reset_column_information

    bot = TeamBot.where(identifier: 'keep').last
    bot.settings = [
      { "name" => "archive_archive_is_enabled",  "label"=>"Enable Archive.is",  "type"=>"boolean", "default"=>"false" },
      { "name" => "archive_archive_org_enabled", "label"=>"Enable Archive.org", "type"=>"boolean", "default"=>"false" },
      { "name" => "archive_keep_backup_enabled", "label"=>"Enable Video Vault", "type"=>"boolean", "default"=>"false" }
    ]
    bot.save!

    TeamBotInstallation.find_each do |installation|
      settings = {}
      installation.team.settings.select{ |key, _value| key.to_s =~ /^archive_.*_enabled/ }.each do |key, value|
        settings[key] = value.to_i == 1
      end
      installation.settings = settings
      installation.save!
    end
    
    CONFIG['clamav_service_path'] = config
  end
end
