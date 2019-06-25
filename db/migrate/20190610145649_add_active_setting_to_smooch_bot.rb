class AddActiveSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << { name: 'smooch_message_smooch_bot_disabled', label: 'Message sent to user when this bot is disabled and not accepting requests', type: 'string', default: '' }
      settings << { name: 'smooch_disabled', label: 'Disable', type: 'boolean', default: 'false' }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
