class FixSmoochBotSettings < ActiveRecord::Migration[4.2]
  def change
    b = BotUser.smooch_user
    unless b.nil?
      settings = b.settings.deep_dup.with_indifferent_access
      settings[:settings].each_with_index do |s, i|
        if s[:name] == 'smooch_workflows'
          settings[:settings][i][:default] = [{ smooch_workflow_language: 'en' }]
          settings[:settings][i][:label] = 'Workflows'
          settings[:settings][i][:items][:properties]['smooch_custom_resources'] = {
            title: 'Resources',
            type: 'array',
            default: [],
            items: {
              title: 'Resource',
              type: 'object',
              properties: {
                smooch_custom_resource_id: {
                  type: 'string',
                  title: 'Title',
                  default: '',
                },
                smooch_custom_resource_title: {
                  type: 'string',
                  title: 'Title',
                  default: '',
                },
                smooch_custom_resource_body: {
                  type: 'string',
                  title: 'Body',
                  default: '',
                },
                smooch_custom_resource_feed_url: {
                  type: 'string',
                  title: 'Feed URL',
                  default: '',
                },
                smooch_custom_resource_number_of_articles: {
                  type: 'integer',
                  title: 'Number of articles',
                  default: 3,
                }
              }
            }
          }
          s[:items][:properties].each do |key, _value|
            if key.to_s =~ /^smooch_state_/
              settings[:settings][i][:items][:properties][key][:properties][:smooch_menu_options][:items][:properties][:smooch_menu_option_value][:enum] << { key: 'custom_resource', value: 'Create new resource' }
              settings[:settings][i][:items][:properties][key][:properties][:smooch_menu_options][:items][:properties][:smooch_menu_custom_resource_id] = { type: 'string', title: 'Custom resource ID', default: '' }
            end
          end
        end
      end
      b.settings = settings
      b.save!
    end
  end
end
