class ChangeSmoochBotSettingsLabels < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
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
