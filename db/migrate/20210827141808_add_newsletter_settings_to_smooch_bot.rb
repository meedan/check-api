class AddNewsletterSettingsToSmoochBot < ActiveRecord::Migration[4.2]
  def change
    b = BotUser.smooch_user
    unless b.nil?
      settings = b.settings.deep_dup.with_indifferent_access
      settings[:settings].each_with_index do |s, i|
        if s[:name] == 'smooch_workflows'

          # Add a new property: Newsletter

          settings[:settings][i][:items][:properties]['smooch_newsletter'] = {
            title: 'Newsletter',
            type: 'object',
            properties: {
              smooch_newsletter_day: {
                type: 'string',
                title: 'Day',
                default: '',
              },
              smooch_newsletter_time: {
                type: 'string',
                title: 'Time',
                default: '',
              },
              smooch_newsletter_timezone: {
                type: 'string',
                title: 'Timezone',
                default: '',
              },
              smooch_newsletter_body: {
                type: 'string',
                title: 'Body',
                default: '',
              },
              smooch_newsletter_feed_url: {
                type: 'string',
                title: 'Feed URL',
                default: '',
              },
              smooch_newsletter_number_of_articles: {
                type: 'integer',
                title: 'Number of articles',
                default: 3,
              }
            }
          }

          # Add a new menu-like state: Subscription opt-in

          settings[:settings][i][:items][:properties]['smooch_state_subscription'] = {
            type: 'object',
            title: 'Subscription opt-in',
            properties: {
              smooch_menu_message: {
                type: 'string',
                title: 'Message',
                default: ''
              },
              smooch_menu_options: {
                title: 'Menu options',
                type: 'array',
                default: [],
                items: {
                  title: 'Option',
                  type: 'object',
                  properties: {
                    smooch_menu_option_keyword: {
                      title: 'If',
                      type: 'string',
                      default: ''
                    },
                    smooch_menu_option_value: {
                      title: 'Then',
                      type: 'string',
                      enum: [
                        {
                          key: 'main_state',
                          value: 'Main menu'
                        },
                        {
                          key: 'subscription_confirmation',
                          value: 'Subscription confirmation'
                        },
                      ],
                      default: ''
                    },
                  }
                }
              }
            }
          }

          s[:items][:properties].each do |key, _value|
            if key.to_s =~ /^smooch_state_/ && key.to_s != 'smooch_state_subscription' && settings[:settings][i][:items][:properties][key][:properties][:smooch_menu_options][:items][:properties][:smooch_menu_option_value][:enum].select{ |x| x.with_indifferent_access[:key] == 'subscription_state' }.empty?
              settings[:settings][i][:items][:properties][key][:properties][:smooch_menu_options][:items][:properties][:smooch_menu_option_value][:enum] << { key: 'subscription_state', value: 'Subscription opt-in' }
            end
          end
        end
      end
      b.settings = settings
      b.save!
    end
  end
end
