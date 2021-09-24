class AddTemplateLocalesSettingToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.push({
        name: 'smooch_template_locales',
        label: 'Choose which locales are supported by the templates',
        type: 'array',
        items: { type: 'string', enum: ['en'] },
        default: ['en']
      })
      tb.set_settings(settings)
      tb.save!
    end
  end
end
