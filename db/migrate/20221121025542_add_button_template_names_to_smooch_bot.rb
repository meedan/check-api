class AddButtonTemplateNamesToSmoochBot < ActiveRecord::Migration[5.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      # Add new template settings
      ['more_information_with_button', 'fact_check_report_with_button', 'fact_check_report_updated_with_button', 'newsletter_with_button'].each do |name|
        settings << {
          name: "smooch_template_name_for_#{name}",
          label: "Template name for template '#{name}'",
          type: 'string',
          default: ''
        }
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
