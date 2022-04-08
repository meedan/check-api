require 'active_support/concern'

module SmoochResend
  extend ActiveSupport::Concern

  # WhatsApp requires pre-approved, pre-defined message templates for messages send outside the 24h window
  module WhatsAppResend
    def should_resend_whatsapp_message?(message)
      message.dig('destination', 'type') == 'whatsapp' && message.dig('error', 'underlyingError', 'errors', 0, 'code') == 470
    end

    def resend_whatsapp_message_after_window(message, original)
      # Exit if there is no template namespace
      return false if self.config['smooch_template_namespace'].blank?

      # This is a report that was created or updated, or a message send by a rule action, or a newsletter
      unless original.blank?
        original = JSON.parse(original)
        output = nil
        output = self.resend_whatsapp_report_after_window(message, original) if original['fallback_template'] =~ /report/
        output = self.resend_rules_message_after_window(message, original) if original['fallback_template'] == 'fact_check_status'
        output = self.resend_newsletter_after_window(message, original) if original['fallback_template'] == 'newsletter'
        return output unless output.nil?
      end

      # A message sent from Slack
      return self.resend_slack_message_after_window(message)
    end

    def resend_rules_message_after_window(message, original)
      template = original['fallback_template']
      language = self.get_user_language(message)
      query_date = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
      placeholders = [query_date, original['message']]
      fallback = original['message']
      self.send_message_to_user(message['appUser']['_id'], self.format_template_message(template, placeholders, nil, fallback, language))
      true
    end

    def resend_whatsapp_report_after_window(message, original)
      pm = ProjectMedia.where(id: original['project_media_id']).last
      report = self.get_report_data_to_be_resent(message, original)
      unless report.nil?
        template = original['fallback_template']
        language, query_date, text, image = report.values_at(:language, :query_date, :text, :image)
        last_smooch_response = self.send_message_to_user(message['appUser']['_id'], self.format_template_message("#{template}_image_only", [query_date], image, image, language)) unless image.blank?
        last_smooch_response = self.send_message_to_user(message['appUser']['_id'], self.format_template_message("#{template}_text_only", [query_date, text], nil, text, language)) unless text.blank?
        self.save_smooch_response(last_smooch_response, pm, query_date, 'fact_check_report', language)
        return true
      end
      false
    end

    def resend_slack_message_after_window(message)
      text = self.get_original_slack_message_text_to_be_resent(message)
      if text
        language = self.get_user_language({ 'authorId' => message['appUser']['_id'] })
        date = Rails.cache.read("smooch:last_message_from_user:#{message['appUser']['_id']}").to_i || Time.now.to_i
        query_date = I18n.l(Time.at(date), locale: language, format: :short)
        self.send_message_to_user(message['appUser']['_id'], self.format_template_message('more_information_needed_text_only', [query_date, text], nil, text, language))
        return true
      end
      false
    end

    def resend_newsletter_after_window(message, original)
      template_name = self.config['smooch_template_name_for_newsletter']
      language = original['language']
      date = I18n.l(Time.now, locale: language, format: :short)
      introduction = original['introduction']
      response = self.send_message_to_user(message['appUser']['_id'], self.format_template_message(template_name, [date, introduction], nil, introduction, language))
      id = self.get_id_from_send_response(response)
      Rails.cache.write("smooch:original:#{id}", 'newsletter') # This way if "Read now" is clicked, the newsletter can be sent
      return true
    end
  end

  module FacebookMessengerResend
    def should_resend_facebook_messenger_message?(message)
      message.dig('destination', 'type') == 'messenger' && message.dig('error', 'code') == 'blocked'
    end

    def message_tags_payload(text, image = nil)
      message = {}
      message[:text] = text if text
      message[:attachment] = { type: 'image', payload: { url: image, is_reusable: true } } if image
      {
        override: {
          messenger: {
            payload: {
              message: message,
              messaging_type: 'MESSAGE_TAG',
              tag: 'ACCOUNT_UPDATE'
            }
          }
        }
      }
    end

    def resend_facebook_messenger_message_after_window(message, original)
      original = JSON.parse(original) unless original.blank?
      uid = message['appUser']['_id']

      return self.resend_facebook_messenger_report_after_window(message, original) if original&.dig('fallback_template') =~ /report/

      # A status message
      if original&.dig('fallback_template') == 'fact_check_status'
        text = original['message']
        self.send_message_to_user(uid, text, self.message_tags_payload(text))
        return true
      end

      # A message sent from Slack
      text = self.get_original_slack_message_text_to_be_resent(message)
      self.send_message_to_user(uid, text, self.message_tags_payload(text))
      return !text.blank?
    end

    def resend_facebook_messenger_report_after_window(message, original)
      pm = ProjectMedia.where(id: original['project_media_id']).last
      report = self.get_report_data_to_be_resent(message, original)
      unless report.nil?
        language, query_date, introduction, text, image = report.values_at(:language, :query_date, :introduction, :text, :image)
        uid = message['appUser']['_id']
        last_smooch_response = nil
        last_smooch_response = self.send_message_to_user(uid, introduction, self.message_tags_payload(introduction)) if introduction
        last_smooch_response = self.send_message_to_user(uid, 'Visual Card', self.message_tags_payload(nil, image)) if image
        last_smooch_response = self.send_message_to_user(uid, text, self.message_tags_payload(text)) if text
        self.save_smooch_response(last_smooch_response, pm, query_date, 'fact_check_report', language)
        return true
      end
      false
    end
  end

  module ClassMethods
    include WhatsAppResend
    include FacebookMessengerResend

    def resend_message(message)
      self.should_resend_message?(message) ? self.delay_for(1.second, { queue: 'smooch', retry: 0 }).resend_message_after_window(message.to_json) : self.log_resend_error(message)
    end

    def should_resend_message?(message)
      self.should_resend_whatsapp_message?(message) || self.should_resend_facebook_messenger_message?(message) || false
    end

    def log_resend_error(message)
      self.notify_error(SmoochBotDeliveryFailure.new('Could not deliver message to final user!'), message, RequestStore[:request]) if message['isFinalEvent']
    end

    def template_locale_options(team_slug = nil)
      team = team_slug.nil? ? Team.current : Team.where(slug: team_slug).last
      languages = team&.get_languages
      languages.blank? ? ['en'] : languages
    end

    def format_template_message(template_name, placeholders, image, fallback, language, header = nil)
      namespace = self.config['smooch_template_namespace']
      return '' if namespace.blank?
      template = self.config["smooch_template_name_for_#{template_name}"] || template_name
      default_language = Team.where(id: self.config['team_id'].to_i).last&.default_language
      locale = (!language.blank? && [self.config['smooch_template_locales']].flatten.include?(language)) ? language : default_language
      if RequestStore.store[:smooch_bot_provider] == 'TURN'
        self.turnio_format_template_message(namespace, template, fallback, locale, image, placeholders)
      else
        self.zendesk_format_template_message(namespace, template, fallback, locale, image, placeholders, header)
      end
    end

    def resend_message_after_window(message)
      message = JSON.parse(message)
      original = Rails.cache.read('smooch:original:' + message['message']['_id'])
      platform = message.dig('destination', 'type')
      self.get_installation(self.installation_setting_id_keys, message['app']['_id'])
      return resend_whatsapp_message_after_window(message, original) if platform == 'whatsapp'
      return resend_facebook_messenger_message_after_window(message, original) if platform == 'messenger'
    end

    def get_original_slack_message_text_to_be_resent(message)
      result = self.smooch_api_get_messages(message['app']['_id'], message['appUser']['_id'], { after: (message['timestamp'].to_i - 120) })
      return nil if result.nil?
      result.messages.each do |m|
        return m.text if m.source&.type == 'slack' && m.id == message['message']['_id']
      end
      nil
    end

    def get_report_data_to_be_resent(message, original)
      pm = ProjectMedia.where(id: original['project_media_id']).last
      report = pm&.get_dynamic_annotation('report_design')
      data = nil
      if report&.get_field_value('state') == 'published'
        data = {}
        data[:language] = language = self.get_user_language({ 'authorId' => message['appUser']['_id'] })
        data[:query_date] = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
        data[:introduction] = report.report_design_field_value('use_introduction', language) ? report.report_design_introduction({ 'received' => original['query_date'].to_i }, language).to_s : nil
        data[:text] = report.report_design_field_value('use_text_message', language) ? report.report_design_text(language).to_s : nil
        data[:image] = report.report_design_field_value('use_visual_card', language) ? report.report_design_image_url(language).to_s : nil
      end
      data
    end
  end
end
