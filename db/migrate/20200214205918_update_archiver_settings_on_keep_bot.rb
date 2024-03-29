class UpdateArchiverSettingsOnKeepBot < ActiveRecord::Migration[4.2]
  def change
    bot = BotUser.keep_user
    settings = bot.get_settings

    settings.each do |s|
      s['default'] = false if s['name'] == 'archive_archive_is_enabled'
    end

    settings << { "name" => "archive_video_archiver_enabled",  "label" => "Enable Video Archiver",  "type" => "boolean", "default" => "false" }
    bot.set_settings(settings)
    bot.save!
  end
end
