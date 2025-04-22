class UpdateSmoochBotDefaultSettings < ActiveRecord::Migration[6.1]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      if i >= 0
        settings[i]['default'] = ::Bot::Smooch.default_settings.clone 
        tb.set_settings(settings)
        tb.save!
      end
    end
  end
end
