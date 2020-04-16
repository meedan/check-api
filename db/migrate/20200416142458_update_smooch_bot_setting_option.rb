class UpdateSmoochBotSettingOption < ActiveRecord::Migration
  def change
    bot = BotUser.where(login: 'smooch').last
    unless bot.nil? 
      settings = bot.get_settings.clone || []
      i = 0
      settings.each do |setting|
        setting = setting.with_indifferent_access
        if setting['name'] =~ /^smooch_state_/
          settings[i]['properties']['smooch_menu_options']['items']['properties']['smooch_menu_option_value']['enum'][2]['value'] = 'Query prompt'
        end
        i += 1
      end
      bot.set_settings(settings)
      bot.save!
    end
  end
end
