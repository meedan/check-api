class DefineDefaultSettingsForKeepBot < ActiveRecord::Migration
  def change
    config = CheckConfig.get('clamav_service_path')
    CheckConfig.set('clamav_service_path', nil)

    bot = BotUser.keep_user
    unless bot.nil?
      bot.set_settings([
        { "name" => "archive_archive_is_enabled",  "label" => "Enable Archive.is",  "type" => "boolean", "default" => "true" },
        { "name" => "archive_archive_org_enabled", "label" => "Enable Archive.org", "type" => "boolean", "default" => "true" }
      ])
      bot.save!
    end
    
    CheckConfig.set('clamav_service_path', config)
  end
end
