class Bot::Viber < BotUser

  check_settings

  attr_accessor :token

  include ViberBotScreenshot

  def self.default
    Bot::Viber.new
  end

  def send_message(body)
    uri = URI('https://chatapi.viber.com/pa/send_message')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    req['X-Viber-Auth-Token'] = self.token
    req.body = body
    http.request(req)
  end

  def send_text_message(user_id, text)
    body = { receiver: user_id, sender: { name: 'Bridge' }, type: 'text', text: text }.to_json
    self.send_message(body)
  end

  def send_image_message(user_id, image)
    body = { receiver: user_id, sender: { name: 'Bridge' }, type: 'picture', text: '', media: image }.to_json
    self.send_message(body)
  end

  DynamicAnnotation::Field.class_eval do
    include CheckElasticSearch

    validate :translation_request_id_is_unique, on: :create

    attr_accessor :disable_es_callbacks

    private

    def translation_request_id_is_unique
      if self.field_name == 'translation_request_id' &&
         DynamicAnnotation::Field.where(field_name: 'translation_request_id', value: self.value).exists?
        errors.add(:base, I18n.t(:translation_request_id_exists))
      end
    end
  end

  Dynamic.class_eval do
    def from_language(locale = 'en')
      if self.annotation_type == 'translation'
        lang = nil
        begin
          lang = CheckCldr.language_code_to_name(self.annotated.get_dynamic_annotation('language').get_field('language').value, locale)
        rescue
          lang = nil
        end
        lang
      end
    end

    def translation_to_message
      if self.annotation_type == 'translation'
        begin
          viber_user_locale = nil
          begin
            viber_user_locale = JSON.parse(self.annotated.get_dynamic_annotation('translation_request').get_field_value('translation_request_raw_data'))['originalRequest']['sender']['language']
            viber_user_locale = 'en' unless I18n.available_locales.include?(viber_user_locale.to_sym)
          rescue
            viber_user_locale = 'en'
          end
          source_language = self.from_language(viber_user_locale)
          source_text = self.annotated.text
          language_code = self.get_field('translation_language').value
          target_language = CheckCldr.language_code_to_name(language_code, viber_user_locale)
          target_text = self.get_field_value('translation_text')
          { source_language: source_language, source_text: source_text, target_language: target_language, target_text: target_text, language_code: language_code.downcase, locale: viber_user_locale }
        rescue
          ''
        end
      end
    end

    def translation_to_message_as_text
      text = ''
      if self.annotation_type == 'translation'
        m = self.translation_to_message
        if m.is_a?(Hash)
          message = [m[:source_text], '', m[:target_language].to_s + ':', m[:target_text]]
          message.unshift(m[:source_language] + ':') unless m[:source_language].blank?
          text = message.join("\n")
        end
      end
      text
    end

    def translation_to_message_as_image
      if self.annotation_type == 'translation'
        m = self.translation_to_message
        imagefilename = Bot::Viber.default.text_to_image(m) if m.is_a?(Hash)
        CONFIG['checkdesk_base_url'] + '/viber/' + imagefilename.to_s + '.jpg'
      end
    end
  end

  ProjectMedia.class_eval do
    alias_method :report_type_original, :report_type

    def report_type
      self.get_annotations('translation_request').any? ? 'translation_request' : self.report_type_original
    end

    def target_languages
      CheckCldr.localized_languages.to_json
    end
  end
end
