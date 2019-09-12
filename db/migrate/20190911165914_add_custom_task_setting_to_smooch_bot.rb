class AddCustomTaskSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.insert(-3, { name: 'smooch_task', label: 'Specify a team task that can contain a custom URL with verification results', type: 'number', default: '' })
      tb.set_settings(settings)
      tb.save!
    end
  end
end
