class AddUrlsToIgnoreSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      new_setting = {
        name: 'smooch_urls_to_ignore',
        label: "URLs to ignore when sent to the tipline, separated by spaces (won't be parsed as an item)",
        type: 'string',
        default: ''
      }
      settings.insert(5, new_setting)
      tb.set_settings(settings)
      tb.save!
    end
  end
end
