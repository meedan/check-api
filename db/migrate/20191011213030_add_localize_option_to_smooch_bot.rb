class AddLocalizeOptionToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << { name: 'smooch_localize_messages', label: 'Localize custom messages', type: 'boolean', default: 'false' }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
