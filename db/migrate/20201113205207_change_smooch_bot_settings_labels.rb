class ChangeSmoochBotSettingsLabels < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_project_id' }
      settings[i]['label'] = 'Tipline incoming list ID'
      i = settings.find_index{ |s| s['name'] == 'smooch_disabled' }
      settings[i]['label'] = 'Deactivate the bot'
      tb.set_settings(settings)
      tb.save!
    end
  end
end
