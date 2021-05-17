class UpdateSmoochBotListSettingsLabel < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_project_id' }
      settings[i]['label'] = 'Incoming folder ID'
      tb.set_settings(settings)
      tb.save!
    end
  end
end
