require 'active_support/concern'

module SmoochMenus
  extend ActiveSupport::Concern

  module ClassMethods
    def is_v2?
      self.config['smooch_version'] == 'v2'
    end

    def send_message_to_user_with_main_menu_appended(uid, text, workflow, language)
      main = []
      counter = 1
      number_of_options = 0

      # Main section and secondary menu
      allowed_types = ['query_state', 'subscription_state', 'custom_resource']
      ['smooch_state_main', 'smooch_state_secondary'].each_with_index do |state, i|
        rows = []
        options = workflow[state].to_h['smooch_menu_options'].to_a
        next if options.empty?
        options.select{ |o| allowed_types.include?(o['smooch_menu_option_value']) }.each do |option|
          title = option['smooch_menu_option_label']
          title ||= BotResource.find_by_uuid(option['smooch_menu_custom_resource_id'])&.title if option['smooch_menu_option_value'] == 'custom_resource'
          title ||= option['smooch_menu_option_value']
          row = {
            id: { state: 'main', keyword: counter.to_s }.to_json,
            title: title.truncate(24)
          }
          row[:description] = option['smooch_menu_option_description'].to_s.truncate(72) unless option['smooch_menu_option_description'].blank?
          rows << row
          number_of_options += 1
          counter = self.get_next_menu_item_number(counter)
        end
        section_title = workflow[state].to_h['smooch_menu_title'] || (i + 1).to_s
        main << {
          title: section_title.truncate(24),
          rows: rows
        }
      end

      # Languages and privacy
      rows = []
      languages = self.get_supported_languages
      title = self.get_menu_string('privacy_title', language, 24)
      if languages.size > 1
        title = self.get_menu_string('languages_and_privacy_title', language, 24)
        languages.reject{ |l| l == language }.sort.each do |l|
          rows << {
            id: { state: 'main', keyword: counter.to_s }.to_json,
            title: ::CheckCldr.language_code_to_name(l, l).truncate(24)
          }
          number_of_options += 1
          counter = self.get_next_menu_item_number(counter)
        end
        rows = self.adjust_language_options(rows, language, number_of_options)
      end
      rows << {
        id: { state: 'main', keyword: '9' }.to_json,
        title: self.get_menu_string('privacy_statement', language, 24)
      }
      number_of_options += 1
      main << {
        title: title,
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
                  sections: main.reject{ |m| m[:rows].empty? }
                }
              }
            }
          }
        }
      }

      fallback = [text]
      main.each do |section|
        fallback << ''
        fallback << section[:title].upcase
        section[:rows].each do |row|
          fallback << self.format_fallback_text_menu_option(row, :id, :title, :description)
        end
      end

      if ['Telegram', 'Viber', 'Facebook Messenger'].include?(self.request_platform)
        actions = []
        main.each do |section|
          section[:rows].each do |row|
            actions << {
              type: 'reply',
              text: row[:title],
              iconUrl: '',
              payload: row[:id],
            }
          end
        end
        extra = { actions: actions }
        fallback = [text]
      end

      self.send_message_to_user(uid, fallback.join("\n"), extra)
    end

    def adjust_language_options(rows, language, number_of_options)
      # WhatsApp just supports up to 10 options, so if we already have 10, we need to replace the
      # individual language options by a single "Languages" option (because we still have the "Privacy and Policy" option)
      new_rows = rows.dup
      new_rows = [{
        id: { state: 'main', keyword: JSON.parse(rows.first[:id])['keyword'] }.to_json,
        title: '🌐 ' + self.get_menu_string('languages', language, 24)
      }] if number_of_options >= 10
      new_rows
    end

    def get_next_menu_item_number(current)
      counter = current
      counter += 1
      counter += 1 if counter == 9 # Skip 9 - fixed option number for privacy statement
      counter
    end

    def get_menu_string(key, language, truncate_at = 1024)
      # Truncation happens because WhatsApp has limitations:
      # - Section title: 24 characters
      # - Menu item title: 24 characters
      # - Menu item description: 72 characters
      # - Button label: 20 characters
      # - Body: 1024 characters
      workflow = self.get_workflow(language) || {}
      label = workflow[key.to_s] || self.get_string(key, language) || {
        # Default values for customizable strings
        cancelled: 'OK! Your submission is canceled.',
        ask_if_ready_state: 'Are you ready to submit?',
        add_more_details_state: 'Please add more content.',
        search_state: 'Thank you! Looking for fact-checks, it may take a minute.',
        search_no_results: 'No fact-checks have been found. Journalists on our team have been notified and you will receive an update in this thread if the information is fact-checked.',
        search_result_state: 'Are these fact-checks answering your question?',
        search_submit: 'Thank you for your feedback. Journalists on our team have been notified and you will receive an update in this thread if a new fact-check is published.',
        search_result_is_relevant: 'Thank you! Spread the word about this tipline to help us fight misinformation! *insert_entry_point_link*',
        newsletter_optin_optout: '{subscription_status}',
        option_not_available: 'Option not available.',
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
      extra, fallback = self.format_fallback_text_menu_from_options(text, options, extra)
      self.send_message_to_user(uid, fallback.join("\n"), extra)
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
      extra, fallback = self.format_fallback_text_menu_from_options(text, options, extra)
      self.send_message_to_user(uid, fallback.join("\n"), extra)
    end

    def format_fallback_text_menu_from_options(text, options, extra)
      fallback = [text, '']
      options.each do |option|
        fallback << self.format_fallback_text_menu_option(option, :value, :label)
      end

      if ['Telegram', 'Viber', 'Facebook Messenger'].include?(self.request_platform)
        actions = []
        options.each do |option|
          actions << {
            type: 'reply',
            text: option[:label],
            iconUrl: '',
            payload: option[:value],
          }
        end
        extra = { actions: actions }
        fallback = [text]
      end

      [extra, fallback]
    end

    def format_fallback_text_menu_option(option, value_key, label_key, description_key = nil)
      value = begin JSON.parse(option[value_key])['keyword'] rescue option[value_key] end
      description = description_key && option[description_key] ? " – #{option[description_key]}" : ''
      "#{value}. #{option[label_key]}#{description}"
    end

    def ask_for_language_confirmation(_workflow, language, uid, with_text = true)
      self.reset_user_language(uid)
      text = []
      options = []
      i = 0
      self.get_supported_languages.sort.each do |l|
        text << self.get_menu_string('confirm_preferred_language', l)
        i = self.get_next_menu_item_number(i)
        options << {
          value: { state: 'main', keyword: i.to_s }.to_json,
          label: ::CheckCldr.language_code_to_name(l, l).truncate(20)
        }
      end
      text = text.join("\n\n")
      if ['Telegram', 'Viber', 'Facebook Messenger'].include?(self.request_platform)
        text = '🌐​' unless with_text
        self.send_message_to_user_with_single_section_menu(uid, text, options, self.get_menu_string('languages', language))
      else
        self.send_message_to_user(uid, text) if with_text
        options.each_slice(3).to_a.each do |sub_options|
          sleep 1 # Try to deliver languages in the correct order
          self.send_message_to_user_with_buttons(uid, '🌐​', sub_options)
        end
      end
    end

    def send_greeting(uid, workflow)
      if self.is_v2?
        text = workflow['smooch_message_smooch_bot_greetings'] || ''
        image = workflow['smooch_greeting_image']
        image.blank? || image == 'none' ? self.send_message_to_user(uid, text) : self.send_message_to_user(uid, text, { 'type' => 'image', 'mediaUrl' => image })
        sleep 2 # Give it some time, so the main menu message is sent after the greetings
      end
    end
  end
end
