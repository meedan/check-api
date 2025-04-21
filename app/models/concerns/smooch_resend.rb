require 'active_support/concern'

module SmoochResend
  extend ActiveSupport::Concern

  # WhatsApp requires pre-approved, pre-defined message templates for messages sent outside the 24h window
  module WhatsAppResend
    def should_resend_whatsapp_message?(message)
      message.dig('destination', 'type') == 'whatsapp' && [470, 131047].include?(message.dig('error', 'underlyingError', 'errors', 0, 'code'))
    end

    def resend_whatsapp_message_after_window(message, original)
      # Exit if there is no template namespace
      return false if self.config['smooch_template_namespace'].blank?

      # This is a report that was created or updated, or a message send by a rule action
      unless original.blank?
        original = JSON.parse(original)
        output = nil
        output = self.resend_whatsapp_report_after_window(message, original) if original['fallback_template'] =~ /report/
        output = self.resend_rules_message_after_window(message, original) if original['fallback_template'] == 'fact_check_status'
        return output unless output.nil?
      end

      # A message sent from Slack
      return self.resend_slack_message_after_window(message)
    end

    def template_exists?(name)
      !self.config["smooch_template_name_for_#{name}"].to_s.strip.blank?
    end

    def get_user_name_from_uid(uid)
      Rails.cache.fetch("smooch:name:#{uid}") do
        begin
          user_data = JSON.parse(DynamicAnnotation::Field.where(value: uid, field_name: 'smooch_user_id').first.annotation.load.get_field_value('smooch_user_data'))
          user_data.dig('raw', 'profile', 'name') || user_data.dig('raw', 'givenName') || '-'
        rescue
          '-'
        end
      end
    end

    def resend_rules_message_after_window(message, original)
      template = original['fallback_template']
      uid = message['appUser']['_id']
      language = self.get_user_language(uid)
      query_date = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
      placeholders = [query_date, original['message']]
      fallback = original['message']
      self.send_message_to_user(uid, self.format_template_message(template, placeholders, nil, fallback, language))
      true
    end

    def resend_whatsapp_report_after_window(message, original)
      pm = ProjectMedia.where(id: original['project_media_id']).last
      report = self.get_report_data_to_be_resent(message, original)
      uid = message['appUser']['_id']
      unless report.nil?
        template = original['fallback_template']
        language, query_date, query_date_i, text, image, title = report.values_at(:language, :query_date, :query_date_i, :text, :image, :title)
        if self.template_exists?("#{template}_with_button")
          name = self.get_user_name_from_uid(uid)
          params = {
            'fact_check_report' => [name, title, query_date],
            'fact_check_report_updated' => [name, title]
          }
          last_smooch_response = self.send_message_to_user(uid, self.format_template_message("#{template}_with_button", params[template], nil, title, language))
          id = self.get_id_from_send_response(last_smooch_response)
          Rails.cache.write("smooch:original:#{id}", "report:#{pm.id}:#{query_date_i}") # This way if "Receive update" or "Receive fact-check" is clicked, the message can be sent
        else
          last_smooch_response = self.send_message_to_user(uid, self.format_template_message("#{template}_image_only", [query_date], image, image, language)) unless image.blank?
          last_smooch_response = self.send_message_to_user(uid, self.format_template_message("#{template}_text_only", [query_date, text], nil, text, language)) unless text.blank?
          self.save_smooch_response(last_smooch_response, pm, query_date, 'fact_check_report', language)
        end
        return true
      end
      false
    end

    def resend_slack_message_after_window(message)
      text = self.get_original_slack_message_text_to_be_resent(message)
      uid = message['appUser']['_id']
      if text
        language = self.get_user_language(uid)
        date = Rails.cache.read("smooch:last_message_from_user:#{uid}").to_i || Time.now.to_i
        query_date = I18n.l(Time.at(date), locale: language, format: :short)
        params = [query_date, text]
        template_name = 'more_information_needed_text_only'
        if self.template_exists?('more_information_with_button')
          template_name = 'more_information_with_button'
          name = self.get_user_name_from_uid(uid)
          params = [name, query_date]
        end
        response = self.send_message_to_user(uid, self.format_template_message(template_name, params, nil, text, language))
        id = self.get_id_from_send_response(response)
        Rails.cache.write("smooch:original:#{id}", "message:#{text}") # This way if "Receive message" is clicked, the message can be sent
        return true
      end
      false
    end

    def send_report_on_template_button_click(_message, uid, language, info)
      self.send_report_to_user(uid, { 'received' => info[2].to_i }, ProjectMedia.find_by_id(info[1].to_i), language, nil)
    end

    def send_message_on_template_button_click(_message, uid, language, info)
      self.send_final_messages_to_user(uid, info[1], self.get_workflow(language), language)
    end

    def clicked_on_template_button?(message)
      ['report', 'message', 'newsletter'].include?(self.get_information_from_clicked_template_button(message).first.to_s)
    end

    def get_information_from_clicked_template_button(message, delete = false)
      quoted_id = message.dig('quotedMessage', 'content', '_id')
      unless quoted_id.blank?
        info = Rails.cache.read("smooch:original:#{quoted_id}").to_s
        begin
          original = JSON.parse(info)
          info = ['newsletter', original['language']] if original['fallback_template'] == 'newsletter'
        rescue
          info = info.split(':')
        end
        Rails.cache.delete("smooch:original:#{quoted_id}") if delete
        return info
      end
      []
    end

    def template_button_click_callback(message, uid, language)
      info = self.get_information_from_clicked_template_button(message, true)
      type = info.first
      case type
      when 'report'
        self.send_report_on_template_button_click(message, uid, language, info)
      when 'message'
        self.send_message_on_template_button_click(message, uid, language, info)
      when 'newsletter'
        team_id = self.config['team_id'].to_i
        language = info[1] || language
        self.toggle_subscription(uid, language, team_id, self.get_platform_from_message(message), self.get_workflow(language)) if self.user_is_subscribed_to_newsletter?(uid, language, team_id)
      end
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
      RequestStore.store[:smooch_bot_provider] = 'ZENDESK'

      return self.resend_facebook_messenger_report_after_window(message, original) if original&.dig('fallback_template') =~ /report/

      # A newsletter
      if original&.dig('fallback_template') == 'newsletter'
        newsletter = TiplineNewsletter.where(language: original['language'], team_id: self.config['team_id'].to_i).last
        newsletter_content = newsletter.build_content
        self.send_message_to_user(uid, newsletter_content, self.message_tags_payload(newsletter_content))
        return true
      end

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
      RequestStore.store[:smooch_bot_provider] = 'ZENDESK'
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
      self.should_resend_message?(message) ? self.delay_for(1.second, { queue: 'smooch_priority', retry: 0 }).resend_message_after_window(message.to_json) : self.log_resend_error(message)
    end

    def should_resend_message?(message)
      self.should_resend_whatsapp_message?(message) || self.should_resend_facebook_messenger_message?(message) || false
    end

    def log_resend_error(message)
      if message['isFinalEvent']
        error = message['error'].to_h
        exception = Bot::Smooch::FinalMessageDeliveryError.new("(#{error['code']}) #{error['message']}")
        CheckSentry.notify(exception, error: error, uid: message.dig('appUser', '_id'), smooch_app_id: message.dig('app', '_id'), timestamp: message['timestamp'])
      end
    end

    def template_locale_options(team_slug = nil)
      team = team_slug.nil? ? Team.current : Team.where(slug: team_slug).last
      languages = team&.get_languages
      languages.blank? ? ['en'] : languages
    end

    def format_template_message(template_name, placeholders, file_url, fallback, language, file_type = 'image', preview_url = true)
      provider = RequestStore.store[:smooch_bot_provider]
      namespace = self.config['smooch_template_namespace']
      template = self.config["smooch_template_name_for_#{template_name}"] || template_name
      return '' if ['TURN', 'CAPI'].include?(provider) && (namespace.blank? || template.blank?)
      default_language = Team.where(id: self.config['team_id'].to_i).last&.default_language
      locale = (!language.blank? && [self.config['smooch_template_locales']].flatten.include?(language)) ? language : default_language
      # Placeholders are mandatory in WhatsApp templates, so let's be sure they are not blank and don't contain spaces, which can mess up with formatting, like bold
      safe_placeholders = placeholders.collect{ |placeholder| placeholder.blank? ? '-' : placeholder.strip }
      if provider == 'TURN'
        self.turnio_format_template_message(namespace, template, fallback, locale, file_url, safe_placeholders, file_type, preview_url)
      elsif provider == 'CAPI'
        self.capi_format_template_message(namespace, template, fallback, locale, file_url, safe_placeholders, file_type, preview_url)
      else
        self.zendesk_format_template_message(namespace, template, fallback, locale, file_url, safe_placeholders, file_type)
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
      explainer = ExplainerItem.find_by_id(original['explainer_item_id'].to_i)&.explainer
      report = nil
      data = nil
      if pm&.get_dynamic_annotation('report_design')&.get_field_value('state') == 'published'
        report = pm.get_dynamic_annotation('report_design').report_design_to_tipline_search_result
      elsif explainer.present?
        report = explainer.as_tipline_search_result
      end
      unless report.nil?
        data = {}
        data[:language] = language = self.get_user_language(message['appUser']['_id'])
        data[:query_date] = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
        data[:query_date_i] = original['query_date'].to_i
        data[:text] = report.body
        data[:image] = report.image_url
        data[:title] = report.title
      end
      data
    end
  end
end
