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

  DynamicAnnotation::Field.class_eval do
    validate :translation_status_is_valid
    validate :can_set_translation_status

    after_update :respond_to_user

    attr_accessor :previous_status

    def previous_value
      self.value_was.nil? ? self.value : self.value_was
    end

    private

    def translation_status_is_valid
      if self.field_name == 'translation_status_status'
        options = self.field_instance.settings[:options_and_roles]
        value = self.value.to_sym

        errors.add(:base, I18n.t(:translation_status_not_valid, default: 'Status not valid')) unless options.keys.include?(value)
      end
    end

    def can_set_translation_status
      if self.field_name == 'translation_status_status'
        options = self.field_instance.settings[:options_and_roles]
        value = self.value.to_sym
        old_value = self.previous_value.to_sym
        self.previous_status = old_value
        user = User.current

        if !user.nil? && !options[value].blank? && (!user.role?(options[value]) || !user.role?(options[old_value]))
          errors.add(:base, I18n.t(:translation_status_permission_error), default: 'You are not allowed to make this status change')
        end
      end
    end

    def respond_to_user
      if self.field_name == 'translation_status_status'
        translation = self.annotation.annotated.get_dynamic_annotation('translation')
        if !translation.nil? && self.previous_status.to_s != self.value.to_s
          translation.respond_to_user(true) if self.value == 'ready' 
          translation.respond_to_user(false) if self.value == 'error'
        end
      end
    end
  end

  Dynamic.class_eval do
    after_create :create_first_translation_status

    def translation_to_message
      if self.annotation_type == 'translation'
        begin
          source_language = self.annotated.get_dynamic_annotation('language').get_field('language').to_s
          source_text = self.annotated.text
          target_language = self.get_field('translation_language').to_s
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

    def self.respond_to_user(tid, success = true)
      translation = Dynamic.where(id: tid).last
      return if translation.nil?
      request = translation.annotated.get_dynamic_annotation('translation_request')
      if !request.nil? && request.get_field_value('translation_request_type') == 'viber'
        data = JSON.parse(request.get_field_value('translation_request_raw_data'))
        if success
          Bot::Viber.default.send_text_message(data['sender'], translation.translation_to_message)
          Bot::Viber.default.send_image_message(data['sender'], translation.translation_to_message_as_image)
        else
          message = translation.annotated.get_dynamic_annotation('translation_status').get_field_value('translation_status_note')
          Bot::Viber.default.send_text_message(data['sender'], message) unless message.blank?
        end
      end
    end

    def respond_to_user(success = true)
      if !CONFIG['viber_token'].blank? && self.annotation_type == 'translation' && self.annotated_type == 'ProjectMedia'
        Dynamic.delay_for(1.second).respond_to_user(self.id, success)
      end
    end
    
    private

    def create_first_translation_status
      if self.annotation_type == 'translation_request'
        ts = Dynamic.new
        ts.skip_check_ability = true
        ts.annotation_type = 'translation_status'
        ts.annotated = self.annotated
        ts.set_fields = { translation_status_status: 'pending', translation_status_note: '' }.to_json
        ts.save!
      end
    end
  end

  # All GraphQL types can have access to the translation_statuses

  GraphqlCrudOperations.class_eval do
    singleton_class.send(:alias_method, :define_default_type_original, :define_default_type)

    def self.define_default_type(&block)
      GraphqlCrudOperations.define_default_type_original do
        field :translation_statuses, types.String do
          resolve -> (_obj, _args, ctx) {
            fi = DynamicAnnotation::FieldInstance.where(name: 'translation_status_status').last
            return '{}' if fi.nil?
            statuses = []
            fi.settings[:statuses].each do |status|
              status[:label] = I18n.t("label_translation_status_#{status[:id]}".to_sym, default: status[:label])
              statuses << status
            end
            { label: 'translation_status', default: 'pending', statuses: statuses }.to_json 
          }
        end

        instance_eval(&block)
      end
    end
  end
end
