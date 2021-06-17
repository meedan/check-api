class AddTurnioSettingsToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      settings << {
        name: "turnio_token",
        label: "Turn.io token",
        type: 'string',
        default: ''
      }
      settings << {
        name: "turnio_secret",
        label: "Turn.io webhook secret",
        type: 'string',
        default: ''
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
