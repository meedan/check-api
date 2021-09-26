class RenameTurnIoSmoochBotSettings < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.where(login: 'smooch').last
    unless tb.nil?
      settings = tb.get_settings.clone
      tb.get_settings.each_with_index do |setting, i|
        s = setting.with_indifferent_access
        if s[:name] == 'turnio_token'
          settings[i][:label] = 'WhatsApp BSP token'
        end
        if s[:name] == 'turnio_secret'
          settings[i][:label] = 'WhatsApp BSP secret'
        end
      end
      settings << {
        name: 'turnio_host',
        label: 'WhatsApp BSP host',
        type: 'string',
        default: 'https://whatsapp.turn.io'
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
