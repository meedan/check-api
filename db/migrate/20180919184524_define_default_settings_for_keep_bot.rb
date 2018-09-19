class DefineDefaultSettingsForKeepBot < ActiveRecord::Migration
  def change
    bot = TeamBot.where(identifier: 'keep').last
    unless bot.nil?
      bot.settings = [
        { "name" => "archive_archive_is_enabled",  "label" => "Enable Archive.is",  "type" => "boolean", "default" => "true" },
        { "name" => "archive_archive_org_enabled", "label" => "Enable Archive.org", "type" => "boolean", "default" => "true" }
      ]
      bot.save!
    end
  end
end
