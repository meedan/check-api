require 'active_support/concern'

module SmoochMessages
  extend ActiveSupport::Concern

  module ClassMethods
    def parse_message(message, app_id)
      uid = message['authorId']
      sm = CheckStateMachine.new(uid)
      if sm.state.value == 'human_mode'
        self.refresh_smooch_slack_timeout(uid)
        return
      end
      self.refresh_smooch_menu_timeout(message, app_id)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      self.delay_for(1.second).save_user_information(app_id, uid) if redis.llen(key) == 0
      self.parse_message_based_on_state(message, app_id)
    end

    def bundle_message(message)
      uid = message['authorId']
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      redis.rpush(key, message.to_json)
    end

    def bundle_messages(uid, id, app_id, type = 'default_requests', annotated = nil)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      list = redis.lrange(key, 0, redis.llen(key))
      unless list.empty?
        last = JSON.parse(list.last)
        if last['_id'] == id || type == 'menu_options_requests'
          self.get_installation('smooch_app_id', app_id) if self.config.blank?
          self.handle_bundle_messages(type, list, last, app_id, annotated)
          redis.del(key)
          sm = CheckStateMachine.new(uid)
          sm.reset
        end
      end
    end

    def get_message_for_state(workflow, state, language)
      message = []
      message << self.tos_message(workflow, language) if state.to_s == 'main'
      message << workflow.dig("smooch_state_#{state}", 'smooch_menu_message')
      message.join("\n\n")
    end

    def send_message_if_disabled_and_return_state(uid, workflow, state)
      disabled = self.config['smooch_disabled']
      self.send_message_to_user(uid, workflow['smooch_message_smooch_bot_disabled'], {}, true) if disabled
      disabled ? 'disabled' : state
    end

    def process_message(message, app_id)
      message['language'] = self.get_user_language(message)

      return if !Rails.cache.read("smooch:banned:#{message['authorId']}").nil?

      hash = self.message_hash(message)
      pm_id = Rails.cache.read("smooch:message:#{hash}")
      if pm_id.nil?
        is_supported = self.supported_message?(message)
        if is_supported.slice(:type, :size).all?{|_k, v| v}
          self.save_message_later_and_reply_to_user(message, app_id)
        else
          self.send_error_message(message, is_supported)
        end
      else
        self.save_message_later_and_reply_to_user(message, app_id)
      end
    end

    def clear_user_bundled_messages(uid)
      Redis.new(REDIS_CONFIG).del("smooch:bundle:#{uid}")
    end

    def handle_bundle_messages(type, list, last, app_id, annotated)
      bundle = last.clone
      text = []
      media = nil
      list.collect{ |m| JSON.parse(m) }.sort_by{ |m| m['received'].to_f }.each do |message|
        next unless self.supported_message?(message)[:type]
        if media.nil?
          media = message['mediaUrl']
          bundle['type'] = message['type']
          bundle['mediaUrl'] = media
        end
        text << message['mediaUrl'].to_s
        text << message['text'].to_s
      end
      bundle['text'] = text.reject{ |t| t.blank? }.join("\n#{Bot::Smooch::MESSAGE_BOUNDARY}") # Add a boundary so we can easily split messages if needed
      if type == 'default_requests'
        self.process_message(bundle, app_id)
      elsif ['timeout_requests', 'menu_options_requests', 'resource_requests'].include?(type)
        key = "smooch:banned:#{bundle['authorId']}"
        self.save_message_later(bundle, app_id, type, annotated) if Rails.cache.read(key).nil?
      end
    end

    def supported_message?(message)
      type = message['type']
      if type == 'file'
        message['mediaType'] = self.detect_media_type(message) if message['mediaType'].blank?
        m = message['mediaType'].to_s.match(/^(image|video|audio)\//)
        type = m[1] unless m.nil?
      end
      message['mediaSize'] ||= 0
      # Define the ret array with keys
      # Type: true if the type supported, size: true if size in allowed range and m_type for message type(image, video, ..)
      ret = { type: true, m_type: type }
      case type
      when 'text'
        ret[:size] = true
      when 'image'
        ret[:size] = message['mediaSize'] <= UploadedImage.max_size
      when 'video'
        ret[:size] = message['mediaSize'] <= UploadedVideo.max_size
      when 'audio'
        ret[:size] = message['mediaSize'] <= UploadedAudio.max_size
      else
        ret = { type: false, size: false }
      end
      ret
    end

    def save_message_later(message, app_id, request_type = 'default_requests', annotated = nil)
      mapping = { 'siege' => 'siege' }
      queue = RequestStore.store[:smooch_bot_queue].to_s
      queue = queue.blank? ? 'smooch' : (mapping[queue] || 'smooch')
      type = (message['type'] == 'text' && !message['text'][/https?:\/\/[^\s]+/, 0].blank?) ? 'link' : message['type']
      SmoochWorker.set(queue: queue).perform_in(1.second, message.to_json, type, app_id, request_type, YAML.dump(annotated))
    end

    def save_message(message_json, app_id, author = nil, request_type = 'default_requests', annotated_obj = nil)
      message = JSON.parse(message_json)
      self.get_installation('smooch_app_id', app_id)
      Team.current = Team.where(id: self.config['team_id']).last
      annotated = nil
      if ['default_requests', 'timeout_requests', 'resource_requests'].include?(request_type)
        message['project_id'] = self.get_project_id(message)
        message['archived'] = request_type == 'default_requests' ? CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS : CheckArchivedFlags::FlagCodes::UNCONFIRMED
        annotated = self.create_project_media_from_message(message)
      elsif 'menu_options_requests' == request_type
        annotated = annotated_obj
      end

      return if annotated.nil?

      # Remember that we received this message.
      hash = self.message_hash(message)
      Rails.cache.write("smooch:message:#{hash}", annotated.id)

      self.smooch_save_annotations(message, annotated, app_id, author, request_type, annotated_obj)
      # If item is published (or parent item), send a report right away
      self.send_report_to_user(message['authorId'], message, annotated, message['language'], 'fact_check_report') if self.should_try_to_send_report?(request_type, annotated)
    end

    def smooch_save_annotations(message, annotated, app_id, author, request_type, annotated_obj)
      # Only save the annotation for the same requester once.
      key = 'smooch:request:' + message['authorId'] + ':' + annotated.id.to_s
      self.create_smooch_request(annotated, message, app_id, author) if !Rails.cache.read(key) || request_type != 'default_requests'
      self.create_smooch_resources_and_type(annotated, annotated_obj, author, request_type) if !Rails.cache.read(key)
      Rails.cache.write(key, hash)
    end

    def create_smooch_request(annotated, message, app_id, author)
      fields = { smooch_data: message.merge({ app_id: app_id }).to_json }
      result = self.smooch_api_get_messages(app_id, message['authorId'])
      fields[:smooch_conversation_id] = result.conversation.id unless result.nil? || result.conversation.nil?
      self.create_smooch_annotations(annotated, author, fields)
    end

    def create_smooch_resources_and_type(annotated, annotated_obj, author, request_type)
      fields = { smooch_request_type: request_type }
      fields[:smooch_resource_id] = annotated_obj.id if request_type == 'resource_requests' && !annotated_obj.nil?
      self.create_smooch_annotations(annotated, author, fields, true)
    end

    def create_smooch_annotations(annotated, author, fields, attach_to = false)
      # TODO: By Sawy - Should handle User.current value
      # In this case User.current was reset by SlackNotificationWorker worker
      # Quick fix - assigning it again using annotated object and reset its value at the end of creation
      current_user = User.current
      User.current = author
      User.current = annotated.user if User.current.nil? && annotated.respond_to?(:user)
      a = nil
      a = Dynamic.where(annotation_type: 'smooch', annotated_id: annotated.id, annotated_type: annotated.class.name).last if attach_to
      if a.nil?
        a = Dynamic.new
        a.annotation_type = 'smooch'
        a.annotated = annotated
      end
      a.skip_check_ability = true
      a.skip_notifications = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.set_fields = fields.to_json
      a.save!
      User.current = current_user
    end

    def should_try_to_send_report?(request_type, annotated)
      request_type == 'default_requests' && (annotated.respond_to?(:is_being_created) && !annotated.is_being_created)
    end

    def resend_message(message)
      code = begin message['error']['underlyingError']['errors'][0]['code'] rescue 0 end
      self.delay_for(1.second, { queue: 'smooch', retry: 0 }).resend_message_after_window(message.to_json) if code == 470
      self.notify_error(SmoochBotDeliveryFailure.new('Could not deliver message to final user!'), message, RequestStore[:request]) if message['isFinalEvent'] && code != 470
    end

    def utmize_urls(text, source)
      entities = Twitter::TwitterText::Extractor.extract_urls_with_indices(text, extract_url_without_protocol: true)
      Twitter::TwitterText::Rewriter.rewrite_entities(text, entities) do |entity, _codepoints|
        url = entity[:url]
        begin
          uri = URI.parse(url)
          new_query_ar = URI.decode_www_form(uri.query.to_s) << ['utm_source', "check_#{source}"]
          uri.query = URI.encode_www_form(new_query_ar)
          uri.to_s
        rescue
          url
        end
      end
    end
  end
end
