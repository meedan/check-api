class RemoveTosSettingFromSmoochBotWorkflow < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      settings[i]['items']['properties'].delete('smooch_message_smooch_bot_ask_for_tos')
      tb.set_settings(settings)
      tb.save!
    end
  end
end
