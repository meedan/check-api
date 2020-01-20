class RemoveTaskSettingFromSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone.select { |setting| setting.with_indifferent_access[:name] != 'smooch_task' }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
