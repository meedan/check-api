class AddNewsletterTemplateNameSettingToSmoochBot < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings << {
        name: 'smooch_template_name_for_newsletter',
        label: 'Template name for template \'newsletter\'',
        type: 'string',
        default: 'newsletter'
      }
      tb.set_settings(settings)
      tb.save!
    end
  end
end
