class AddTemplateLocalesSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.where(login: 'smooch').last
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
