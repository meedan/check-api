class AddVersionToSmoochBot < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << { name: 'smooch_version', label: 'Smooch Bot version', type: 'hidden', default: 'v1' }
      tb.set_settings(settings)
      tb.save!

      TeamBotInstallation.where(user_id: tb.id).each do |tbi|
        tbi.set_smooch_version = 'v1'
        tbi.save!
      end
    end
  end
end
