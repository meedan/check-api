class Bot::Viber < ActiveRecord::Base
  def self.default
    Bot::Viber.where(name: 'Viber Bot').last
  end

  def send_message(body)
    uri = URI('https://chatapi.viber.com/pa/send_message')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    req['X-Viber-Auth-Token'] = CONFIG['viber_token']
    req.body = body 
    http.request(req)
  end

  def send_text_message(user_id, text)
    body = { receiver: user_id, sender: { name: 'Bridge' }, type: 'text', text: text }.to_json
    self.send_message(body)
  end

  def send_image_message(user_id, image)
    body = { receiver: user_id, sender: { name: 'Bridge' }, type: 'picture', text: '', media: CONFIG['checkdesk_base_url'] + image.url }.to_json
    self.send_message(body)
  end

  Dynamic.class_eval do
    after_create :respond_to_user

    def translation_to_message
      if self.annotation_type == 'translation'
        begin
          source_language = self.annotated.get_dynamic_annotation('language').get_field('language').language_name
          source_text = self.annotated.text
          target_language = self.get_field('translation_language').language_name
          target_text = self.get_field_value('translation_text')
          [source_language.to_s + ':', source_text, target_language.to_s + ':', target_text].join("\n")
        rescue
          ''
        end
      end
    end

    def translation_to_message_as_image
      if self.annotation_type == 'translation'
        MagickTitle.say(self.translation_to_message, {
          font: 'freesans.ttf',
          font_path: File.join(Rails.root, 'app', 'assets', 'fonts'),
          font_size: 32,
          extension: 'jpg',
          color: '#000',
          background_alpha: 'ff',
          text_transform: nil
        })    
      end
    end

    def self.respond_to_user(tid)
      translation = Dynamic.where(id: tid).last
      return if translation.nil?
      request = translation.annotated.get_dynamic_annotation('translation_request')
      if !request.nil? && request.get_field_value('translation_request_type') == 'viber'
        data = JSON.parse(request.get_field_value('translation_request_raw_data'))
        Bot::Viber.default.send_text_message(data['sender'], translation.translation_to_message)
        Bot::Viber.default.send_image_message(data['sender'], translation.translation_to_message_as_image)
      end
    end

    private

    def respond_to_user
      if !CONFIG['viber_token'].blank? && self.annotation_type == 'translation' && self.annotated_type == 'ProjectMedia'
        Dynamic.delay_for(1.second).respond_to_user(self.id)
      end
    end
  end
end
