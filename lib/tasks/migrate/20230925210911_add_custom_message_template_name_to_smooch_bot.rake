namespace :check do
  namespace :migrate do
    task add_custom_message_template_name_to_smooch_bot: :environment do |_t, _args|
      tb = BotUser.smooch_user
      unless tb.nil?
        settings = tb.get_settings.clone || []
        # Add new template setting for custom message
        settings << {
          name: 'smooch_template_name_for_custom_message',
          label: "Template name for template 'custom_message'",
          type: 'string',
          default: ''
        }
        tb.set_settings(settings)
        tb.save!
      end
    end
  end
end
