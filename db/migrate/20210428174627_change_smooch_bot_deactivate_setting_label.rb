class ChangeSmoochBotDeactivateSettingLabel < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_disabled' }
      settings[i]['label'] = 'Pause the bot'
      settings[i]['description'] = 'When paused, the bot will send the "Notice of activity" message to any user interacting with the tipline. No other messages will be sent. The tipline will not be deactivated.'
      tb.set_settings(settings)
      tb.save!
    end
  end
end
