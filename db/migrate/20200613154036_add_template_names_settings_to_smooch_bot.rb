class AddTemplateNamesSettingsToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      # Reorder existing template settings
      ['smooch_template_namespace', 'smooch_template_locales'].each do |name|
        i = settings.index{ |s| s.with_indifferent_access[:name] == name }
        setting = settings[i].clone
        settings.delete_at(i)
        settings << setting
      end
      # Add new template settings
      ['fact_check_report', 'fact_check_report_image_only', 'fact_check_report_text_only', 'fact_check_status',
       'fact_check_report_updated', 'fact_check_report_updated_image_only', 'fact_check_report_updated_text_only',
       'more_information_needed', 'more_information_needed_image_only', 'more_information_needed_text_only'
      ].each do |name|
        settings << {
          name: "smooch_template_name_for_#{name}",
          label: "Template name for template '#{name}'",
          type: 'string',
          default: name
        }
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
