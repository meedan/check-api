class UpdateTurnIoSmoochBotSettings < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      settings << {
        name: 'turnio_phone',
        label: 'WhatsApp BSP phone number',
        type: 'string',
        default: ''
      }
      settings << {
        name: 'turnio_cacert',
        label: 'WhatsApp BSP CA Cert',
        type: 'string',
        default: ''
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
