class Workflow::TranslationStatus < Workflow::Base

  check_workflow_default if CONFIG['app_name'] == 'Bridge'

  # When translation status changes, send a message to user on Viber and publish to Twitter / Facebook
  # If this status is "ready", store the user who set that status
  check_workflow from: :any, to: 'ready', actions: :respond_to_user_success
  check_workflow from: :any, to: 'error', actions: :respond_to_user_error
  check_workflow on: :commit, actions: :index_on_es, events: [:create, :update]

  def self.core_default_value
    'pending'
  end

  def self.core_active_value
    'in_progress'
  end
   
  # Custom methods

  DynamicAnnotation::Field.class_eval do
    attr_accessor :translation_published_to_social_media
    
    protected

    def respond_to_user_success
      self.store_approver
      translation = self.annotation.annotated.get_dynamic_annotation('translation')
      Bot::Twitter.default.send_to_twitter_in_background(translation)
      Bot::Facebook.default.send_to_facebook_in_background(translation)
      self.translation_published_to_social_media ||= 0
      self.translation_published_to_social_media += 1
      self.respond_to_user(true)
    end

    def respond_to_user_error
      self.respond_to_user(false)
    end

    def respond_to_user(success)
      request = self.annotation.annotated.get_dynamic_annotation('translation_request')
      request.respond_to_user(success) unless request.nil?
    end

    def store_approver
      if User.current.present?
        url = begin
                User.current.accounts.first.url
              rescue
                nil
              end

        annotation = self.annotation.load
        annotation.disable_es_callbacks = Rails.env.to_s == 'test'
        annotation.set_fields = { translation_status_approver: { name: User.current.name, url: url }.to_json }.to_json
        annotation.save!
      end
    end
  end # DynamicAnnotation::Field.class_eval
  
  Dynamic.class_eval do
    def self.respond_to_user(tid, success, token)
      request = Dynamic.where(id: tid).last
      return if request.nil?
      if request.get_field_value('translation_request_type') == 'viber'
        data = JSON.parse(request.get_field_value('translation_request_raw_data'))
        bot = Bot::Viber.default
        bot.token = token
        if success
          translation = request.annotated.get_dynamic_annotation('translation')
          unless translation.nil?
            bot.send_text_message(data['sender'], translation.translation_to_message_as_text)
            bot.send_image_message(data['sender'], translation.translation_to_message_as_image)
          end
        else
          message = request.annotated.get_dynamic_annotation('translation_status').get_field_value('translation_status_note')
          bot.send_text_message(data['sender'], message) unless message.blank?
        end
      end
    end

    def respond_to_user(success = true)
      if self.annotation_type == 'translation_request' && self.annotated_type == 'ProjectMedia'
        token = self.annotated.project.get_viber_token
        Dynamic.delay_for(1.second, retry: 0).respond_to_user(self.id, success, token) unless token.blank?
      end
    end
  end # Dynamic.class_eval
end
