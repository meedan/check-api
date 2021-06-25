class HideSomeSmoochBotTemplateSettings < ActiveRecord::Migration[4.2]
  def change
    tb = BotUser.smooch_user
    fields_to_hide = ['smooch_template_name_for_fact_check_report', 'smooch_template_name_for_fact_check_report_updated', 'smooch_template_name_for_more_information_needed', 'smooch_template_name_for_more_information_needed_image_only']
    unless tb.nil?
      settings = tb.get_settings.clone || []
      settings.each_with_index do |s, i|
        if fields_to_hide.include?(s.with_indifferent_access[:name])
          settings[i][:type] = 'hidden'
        elsif s.with_indifferent_access[:name].match(/^smooch_template_/)
          settings[i][:label] = s.with_indifferent_access[:label].to_s.gsub('_only', '')
        end
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
