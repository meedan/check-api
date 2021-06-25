class UpdateSmoochBotSettingsForLanguage < ActiveRecord::Migration[4.2]
  def change
    settings_to_remove = ['smooch_message_smooch_bot_result', 'smooch_message_smooch_bot_ask_for_confirmation', 'smooch_message_smooch_bot_message_unconfirmed',
                          'smooch_message_smooch_bot_not_final', 'smooch_message_smooch_bot_meme', 'smooch_message_smooch_bot_window_closing', 'smooch_bot_id',
                          'smooch_window_duration', 'smooch_rules_and_actions', 'smooch_task', 'smooch_localize_messages']

    bot = BotUser.smooch_user
    unless bot.nil?

      # Update the bot schema

      old_settings = bot.settings[:settings].clone
      new_settings = [{
        name: 'smooch_workflows',
        title: 'Workflows',
        type: 'array',
        default: [
          {
            smooch_workflow_language: 'en',
          }
        ],
        items: {
          title: 'Workflow',
          type: 'object',
          properties: {
            smooch_workflow_language: {
              title: 'Language',
              type: 'string',
              default: 'en'
            }
          }
        }
      }]
      old_settings.each do |setting|
        s = setting.with_indifferent_access
        next if settings_to_remove.include?(s[:name].to_s)
        if s[:name] =~ /^smooch_message_/ || s[:name] =~ /^smooch_state_/
          default = bot.get_default_from_setting(s)
          type = s[:type]
          new_setting = {
            type: type,
            title: s[:label]
          }
          if type == 'array'
            new_setting[:items] = s[:items]
          elsif type == 'object'
            new_setting[:properties] = s[:properties]
          else
            new_setting[:default] = default
          end
          new_settings[0][:default] << { s[:name] => default }
          new_settings[0][:items][:properties][s[:name]] = new_setting
        else
          new_settings << setting
        end
      end
      bot.set_settings(new_settings)
      bot.save!
      
      # Update each installation

      bot.team_users.each do |installation|
        puts "Updating Smooch Bot settings for team #{installation.team.name}..."
        new_settings = { smooch_workflows: [{ smooch_workflow_language: 'en' }] }
        old_settings = installation.settings.clone.with_indifferent_access
        old_settings.each do |key, value|
          next if settings_to_remove.include?(key.to_s)
          if key =~ /^smooch_message_/ || key =~ /^smooch_state_/
            new_settings[:smooch_workflows][0][key] = value
          else
            new_settings[key] = value
          end
        end
        installation.settings = new_settings
        installation.save!
      end
    end
  end
end
