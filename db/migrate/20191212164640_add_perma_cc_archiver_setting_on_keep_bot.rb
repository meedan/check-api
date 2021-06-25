class AddPermaCcArchiverSettingOnKeepBot < ActiveRecord::Migration[4.2]
  def change
    bot = BotUser.keep_user
    settings = bot.get_settings
    settings << { "name" => "archive_perma_cc_enabled",  "label" => "Enable Perma.cc",  "type" => "boolean", "default" => "false" }
    bot.set_settings(settings)

    bot.save!
  end
end
