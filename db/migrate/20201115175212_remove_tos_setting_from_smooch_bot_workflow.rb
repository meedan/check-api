class RemoveTosSettingFromSmoochBotWorkflow < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      settings[i]['items']['properties'].delete('smooch_message_smooch_bot_ask_for_tos')
      tb.set_settings(settings)
      tb.save!
    end
  end
end
