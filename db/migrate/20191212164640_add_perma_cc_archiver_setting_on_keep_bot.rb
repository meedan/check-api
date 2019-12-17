class AddPermaCcArchiverSettingOnKeepBot < ActiveRecord::Migration
  def change
    bot = BotUser.where(login: 'keep').last
    settings = bot.get_settings
    settings << { "name" => "archive_perma_cc_enabled",  "label" => "Enable Perma.cc",  "type" => "boolean", "default" => "false" }
    bot.set_settings(settings)

    bot.save!
  end
end
