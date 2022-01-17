require 'active_support/concern'

module SmoochMenus
  extend ActiveSupport::Concern

  module ClassMethods
    def send_message_to_user_with_main_menu_appended(uid, text, workflow, language)
      main = []

      # Main section
      rows = []
      unless workflow['smooch_state_main'].blank?
        workflow['smooch_state_main']['smooch_menu_options'].each do |option|
          if ['query_state', 'subscription_state'].include?(option['smooch_menu_option_value'])
            keyword = option['smooch_menu_option_keyword'].split(',').map(&:strip).first
            rows << {
              id: { state: 'main', keyword: keyword }.to_json,
              title: self.get_menu_string(option['smooch_menu_option_value'], language, 24)
            }
          end
        end
        main << {
          title: self.get_menu_string('smooch_state_main_title', language, 24),
          rows: rows
        }
      end

      # Secondary menu
      rows = []
      unless workflow['smooch_state_secondary'].blank?
        workflow['smooch_state_secondary']['smooch_menu_options'].each do |option|
          if option['smooch_menu_option_value'] == 'custom_resource'
            keyword = option['smooch_menu_option_keyword'].split(',').map(&:strip).first
            rows << {
              id: { state: 'secondary', keyword: keyword }.to_json,
              title: BotResource.find_by_uuid(option['smooch_menu_custom_resource_id'])&.title.to_s.truncate(24)
            }
          end
        end
        main << {
          title: self.get_menu_string('smooch_state_secondary_title', language, 24),
          rows: rows
        } unless rows.empty?
      end

      # Languages and privacy
      rows = []
      self.config['smooch_workflows'].each do |w|
        l = w['smooch_workflow_language']
        next if l == language
        code = l.gsub(/_.*$/, '')
        rows << {
          id: { state: 'main', keyword: l }.to_json,
          title: ::CheckCldr.language_code_to_name(code, code).truncate(24)
        }
      end
      rows << {
        id: { state: 'main', keyword: 9 }.to_json,
        title: self.get_menu_string('privacy_statement', language, 24)
      }
      main << {
        title: self.get_menu_string('languages_and_privacy_title', language, 24),
        rows: rows
      }

      extra = {
        override: {
          whatsapp: {
            payload: {
              recipient_type: 'individual',
              type: 'interactive',
              interactive: {
                type: 'list',
                body: {
                  text: text.truncate(1024)
                },
                action: {
                  button: self.get_menu_string('main_menu', language, 20),
                  sections: main
                }
              }
            }
          }
        }
      }
      self.send_message_to_user(uid, text, extra)
    end

    def get_menu_string(key, language, truncate_at = 1024)
      # Truncation happens because WhatsApp has limitations:
      # - Section title: 24 characters
      # - Menu item title: 24 characters
      # - Menu item description: 72 characters
      # - Button label: 20 characters
      # - Body: 1024 characters
      # FIXME: For now these are hard-coded, but the user will be able to set SOME (see in Airtable the ones that are hard-coded) of them in the UI (this method should still provide a default string in English)
      label = {
        smooch_state_main_title: 'Main',
        query_state: 'Submit new content to fact-check',
        subscription_state: 'Subscribe to our newsletter',
        smooch_state_secondary_title: 'Secondary',
        main_state_button_label: 'Cancel',
        search_state_button_label: 'Submit',
        add_more_details_state_button_label: 'Add more information',
        search_no_results: 'No fact-checks could be found for this content. Thank you for alerting us! Sent to investigation.',
        main_menu: 'Main menu',
        search_state: 'Got it! Let us check this claim',
        ask_if_ready_state: 'Are you ready to submit?',
        add_more_details_state: 'OK! Please add more content. You can also send a video, image or audio file.',
        search_error: 'Error when trying to look for fact-checks. Please try again later.',
        search_result_state: 'Are these articles answering your question?',
        search_submit: 'Thank you for your feedback. Journalists on our team have been notified and you will receive an update in this thread if the information is fact-checked.',
        search_result_is_relevant: 'Thank you for your feedback!',
        search_result_is_relevant_button_label: 'Yes',
        search_result_is_not_relevant_button_label: 'No',
        cancelled: 'OK! Your request has been cancelled.',
        languages_and_privacy_title: 'Languages and Privacy',
        privacy_statement: 'Privacy statement',
        subscription_confirmation_button_label: 'Change',
        message_subscribed: 'You are currently *subscribed* to the newsletter',
        message_unsubscribed: 'You are currently *unsubscribed* to the newsletter',
        confirm_preferred_language: 'Please confirm your preferred language:',
        languages: 'Languages'
      }[key.to_sym] || key
      label.truncate(truncate_at)
    end

    def send_message_to_user_with_buttons(uid, text, options)
      buttons = []
      options.each_with_index do |option, i|
        buttons << {
          type: 'reply',
          reply: {
            id: option[:value],
            title: option[:label]
          }
        } if i < 3 # WhatsApp only allows up to 3 buttons
      end
      extra = {
        override: {
          whatsapp: {
            payload: {
              recipient_type: 'individual',
              type: 'interactive',
              interactive: {
                type: 'button',
                body: {
                  text: text
                },
                action: {
                  buttons: buttons
                }
              }
            }
          }
        }
      }
      self.send_message_to_user(uid, text, extra)
    end

    def send_message_to_user_with_single_section_menu(uid, text, options, menu_label)
      rows = []
      options.each do |option|
        rows << {
          id: option[:value],
          title: option[:label].truncate(24)
        }
      end
      sections = [{
        title: menu_label.truncate(24),
        rows: rows
      }]
      extra = {
        override: {
          whatsapp: {
            payload: {
              recipient_type: 'individual',
              type: 'interactive',
              interactive: {
                type: 'list',
                body: {
                  text: text.truncate(1024)
                },
                action: {
                  button: menu_label.truncate(24),
                  sections: sections
                }
              }
            }
          }
        }
      }
      self.send_message_to_user(uid, text, extra)
    end

    def ask_for_language_confirmation(workflow, language, uid)
      text = [workflow['smooch_message_smooch_bot_greetings'], self.get_menu_string(:confirm_preferred_language, language)].join("\n\n")
      options = self.config['smooch_workflows'].collect do |w|
        l = w['smooch_workflow_language']
        {
          value: { state: 'main', keyword: l }.to_json,
          label: ::CheckCldr.language_code_to_name(l, l).truncate(20)
        }
      end
      if options.size > 3
        self.send_message_to_user_with_single_section_menu(uid, text, options, self.get_menu_string(:languages, language))
      else
        self.send_message_to_user_with_buttons(uid, text, options)
      end
    end
  end
end
