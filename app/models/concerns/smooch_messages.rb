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

    def discard_or_process_message(message, app_id)
      if self.config['smooch_disabled']
        language = self.get_user_language(message)
        workflow = self.get_workflow(language)
        self.send_message_to_user(message['authorId'], workflow['smooch_message_smooch_bot_disabled'], {}, true)
      else
        self.process_message(message, app_id)
      end
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
        message['archived'] = request_type == 'default_requests' ? CheckArchivedFlags::FlagCodes::NONE : CheckArchivedFlags::FlagCodes::UNCONFIRMED
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
      self.send_report_to_user(message['authorId'], message, annotated, message['language']) if request_type == 'default_requests'
    end

    def smooch_save_annotations(message, annotated, app_id, author, request_type, annotated_obj)
      # Only save the annotation for the same requester once.
      key = 'smooch:request:' + message['authorId'] + ':' + annotated.id.to_s
      self.create_smooch_request(annotated, message, app_id, author, request_type) if !Rails.cache.read(key) || request_type != 'default_requests'
      self.create_smooch_resources_and_type(annotated, annotated_obj, author, request_type) if !Rails.cache.read(key)
      Rails.cache.write(key, hash)
    end

    def resend_message(message)
      code = begin message['error']['underlyingError']['errors'][0]['code'] rescue 0 end
      self.delay_for(1.second, { queue: 'smooch', retry: 0 }).resend_message_after_window(message.to_json) if code == 470
      self.notify_error(SmoochBotDeliveryFailure.new('Could not deliver message to final user!'), message, RequestStore[:request]) if message['isFinalEvent'] && code != 470
    end
  end
end
