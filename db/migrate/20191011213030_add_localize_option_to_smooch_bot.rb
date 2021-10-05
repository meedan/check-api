class AddLocalizeOptionToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << { name: 'smooch_localize_messages', label: 'Localize custom messages', type: 'boolean', default: 'false' }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
