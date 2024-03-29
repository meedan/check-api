class AddTosSettingToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.insert(-2, { name: 'smooch_message_smooch_bot_ask_for_tos', label: 'Message sent to user to ask them to agree to the Terms of Service (placeholders: %{tos} (TOS URL))', type: 'string', default: '' })
      tb.set_settings(settings)
      tb.save!
    end
  end
end
