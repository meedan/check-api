require 'active_support/concern'

module SmoochMessages
  extend ActiveSupport::Concern

  module ClassMethods
    def parse_message(message, app_id, payload = nil)
      uid = message['authorId']
      sm = CheckStateMachine.new(uid)
      if sm.state.value == 'human_mode'
        self.refresh_smooch_slack_timeout(uid)
        return
      end
      self.refresh_smooch_menu_timeout(message, app_id)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      self.delay_for(1.second).save_user_information(app_id, uid, payload.to_json) if redis.llen(key) == 0
      self.parse_message_based_on_state(message, app_id)
    end

    def get_smooch_channel(message)
      # Get item channel (message type)
      channel = message.dig('source', 'type')&.upcase
      all_channels = CheckChannels::ChannelCodes.all_channels['TIPLINE']
      all_channels.keys.include?(channel) ? all_channels[channel] : nil
    end

    def bundle_message(message)
      uid = message['authorId']
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      redis.rpush(key, message.to_json)
    end

    def list_of_bundled_messages_from_user(uid)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      redis.lrange(key, 0, redis.llen(key))
    end

    def bundle_messages(uid, id, app_id, type = 'default_requests', annotated = nil, force = false, bundle = nil)
      list = bundle || self.list_of_bundled_messages_from_user(uid)
      unless list.empty?
        last = JSON.parse(list.last)
        if last['_id'] == id || ['menu_options_requests'].include?(type) || force
          self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
          self.handle_bundle_messages(type, list, last, app_id, annotated, !force)
          if bundle.nil?
            self.clear_user_bundled_messages(uid)
            sm = CheckStateMachine.new(uid)
            sm.reset unless sm.state.value == 'main'
          end
        end
      end
    end

    def send_final_message_to_user(uid, text, workflow, language)
      if self.is_v2?
        CheckStateMachine.new(uid).go_to_main
        self.send_message_to_user_with_main_menu_appended(uid, text, workflow, language)
      else
        self.send_message_to_user(uid, text)
      end
    end

    def send_message_for_state(uid, workflow, state, language, pretext = '')
      message = self.utmize_urls(self.get_message_for_state(workflow, state, language, uid).to_s, 'resource')
      text = [pretext, message].reject{ |part| part.blank? }.join("\n\n")
      if self.is_v2?
        if self.should_ask_for_language_confirmation?(uid)
          self.ask_for_language_confirmation(workflow, language, uid)
        else
          # On v2, when we go to the "main" state, we need to show the main menu
          state == 'main' ? self.send_message_to_user_with_main_menu_appended(uid, text, workflow, language) : self.send_message_for_state_with_buttons(uid, text, workflow, state, language)
        end
      else
        self.send_message_to_user(uid, text)
      end
    end

    def send_message_for_state_with_buttons(uid, text, workflow, state, language)
      options = []
      self.get_menu_options(state, workflow, uid).each do |option|
        keyword = option['smooch_menu_option_keyword'].split(',').map(&:strip).first
        value = option['smooch_menu_option_value']
        key = value
        # We use different menu labels for the subscription state, based on the current subscription status (subscribed / unsubscribed)
        if state == 'subscription' && value == 'subscription_confirmation'
          team_id = self.config['team_id']
          key = self.user_is_subscribed_to_newsletter?(uid, language, team_id) ? 'unsubscribe' : 'subscribe'
        end
        options << {
          value: { keyword: keyword }.to_json,
          label: self.get_menu_string("#{key}_button_label", language, 20)
        }
      end
      options.size > 0 ? self.send_message_to_user_with_buttons(uid, text, options) : self.send_message_to_user(uid, text)
    end

    def get_message_for_state(workflow, state, language, uid = nil)
      message = []
      if state.to_s == 'main'
        message << workflow['smooch_message_smooch_bot_greetings']
        message << self.tos_message(workflow, language) if self.config['smooch_version'] != 'v2'
      end
      message << self.subscription_message(uid, language) if state.to_s == 'subscription'
      message << workflow.dig("smooch_state_#{state}", 'smooch_menu_message') if state != 'main' || self.config['smooch_version'] != 'v2'
      message << self.get_menu_string("#{state}_state", language) if ['search', 'search_result', 'add_more_details', 'ask_if_ready'].include?(state.to_s)
      message.reject{ |m| m.blank? }.join("\n\n")
    end

    def subscription_message(uid, language, subscribed = nil, full_message = true)
      subscribed = subscribed.nil? ? !TiplineSubscription.where(team_id: self.config['team_id'], uid: uid, language: language).last.nil? : subscribed
      status = subscribed ? self.get_menu_string('subscribed', language.gsub(/[-_].*$/, '')) : self.get_menu_string('unsubscribed', language.gsub(/[-_].*$/, ''))
      full_message ? self.get_menu_string('newsletter_optin_optout', language).gsub('{subscription_status}', status) : status
    end

    def send_message_if_disabled_and_return_state(uid, workflow, state)
      disabled = self.config['smooch_disabled']
      self.send_message_to_user(uid, workflow['smooch_message_smooch_bot_disabled'], {}, true) if disabled
      disabled ? 'disabled' : state
    end

    def get_platform_from_message(message)
      type = message.dig('source', 'type')
      type ? ::Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[type].to_s : 'Unknown'
    end

    def save_message_later_and_reply_to_user(message, app_id, send_message = true)
      self.save_message_later(message, app_id)
      workflow = self.get_workflow(message['language'])
      uid = message['authorId']
      self.send_message_to_user(uid, utmize_urls(workflow['smooch_message_smooch_bot_message_confirmed'], 'resource')) if send_message
    end

    def message_hash(message)
      hash = nil
      case message['type']
      when 'text'
        hash = Digest::MD5.hexdigest(self.get_text_from_message(message))
      when 'image', 'file'
        open(message['mediaUrl']) do |f|
          hash = Digest::MD5.hexdigest(f.read)
        end
      end
      hash
    end

    def get_text_from_message(message)
      text = message['text'][/[^\s]+\.[^\s]+/, 0].to_s.gsub(/^https?:\/\//, '')
      text = message['text'] if text.blank?
      text.downcase
    end

    def preprocess_message(body)
      if RequestStore.store[:smooch_bot_provider] == 'TURN'
        self.preprocess_turnio_message(body)
      else
        JSON.parse(body)
      end
    end

    def process_message(message, app_id, send_message = true)
      message['language'] = self.get_user_language(message)

      return if !Rails.cache.read("smooch:banned:#{message['authorId']}").nil?

      hash = self.message_hash(message)
      pm_id = Rails.cache.read("smooch:message:#{hash}")
      if pm_id.nil?
        is_supported = self.supported_message?(message)
        if is_supported.slice(:type, :size).all?{ |_k, v| v }
          self.save_message_later_and_reply_to_user(message, app_id, send_message)
        else
          self.send_error_message(message, is_supported)
        end
      else
        self.save_message_later_and_reply_to_user(message, app_id, send_message)
      end
    end

    def clear_user_bundled_messages(uid)
      Redis.new(REDIS_CONFIG).del("smooch:bundle:#{uid}")
    end

    def bundle_list_of_messages(list, last, reject_payload = false)
      bundle = last.clone
      text = []
      media = nil
      list.collect{ |m| JSON.parse(m) }.sort_by{ |m| m['received'].to_f }.each do |message|
        next if reject_payload && message['payload']
        if media.nil?
          media = message['mediaUrl']
          bundle['type'] = message['type']
          bundle['mediaUrl'] = media
        end
        text << message['mediaUrl'].to_s
        text << begin JSON.parse(message['payload'])['keyword'] rescue message['text'] end
      end
      bundle['text'] = text.reject{ |t| t.blank? }.join("\n#{Bot::Smooch::MESSAGE_BOUNDARY}") # Add a boundary so we can easily split messages if needed
      bundle
    end

    def handle_bundle_messages(type, list, last, app_id, annotated, send_message = true)
      bundle = self.bundle_list_of_messages(list, last)
      if type == 'default_requests'
        self.process_message(bundle, app_id, send_message)
      elsif ['timeout_requests', 'menu_options_requests', 'resource_requests', 'relevant_search_result_requests'].include?(type)
        key = "smooch:banned:#{bundle['authorId']}"
        if Rails.cache.read(key).nil?
          [annotated].flatten.uniq.each { |a| self.save_message_later(bundle, app_id, type, a) }
        end
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

    def default_archived_flag
      team_id = self.config['team_id'].to_i
      Bot::Alegre.team_has_alegre_bot_installed?(team_id) ? CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS : CheckArchivedFlags::FlagCodes::NONE
    end

    def save_message(message_json, app_id, author = nil, request_type = 'default_requests', annotated_obj = nil)
      message = JSON.parse(message_json)
      self.get_installation(self.installation_setting_id_keys, app_id)
      Team.current = Team.where(id: self.config['team_id']).last
      annotated = nil
      if ['default_requests', 'timeout_requests', 'resource_requests'].include?(request_type)
        message['archived'] = request_type == 'default_requests' ? self.default_archived_flag : CheckArchivedFlags::FlagCodes::UNCONFIRMED
        annotated = self.create_project_media_from_message(message)
      elsif ['menu_options_requests', 'relevant_search_result_requests'].include?(request_type)
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
      self.create_smooch_request(annotated, message, app_id, author)
      self.create_smooch_resources_and_type(annotated, annotated_obj, author, request_type)
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

    def send_message_on_status_change(pm_id, status, request_actor_session_id = nil)
      RequestStore[:actor_session_id] = request_actor_session_id unless request_actor_session_id.nil?
      pm = ProjectMedia.find_by_id(pm_id)
      return if pm.nil?
      requestors_count = 0
      parent = Relationship.where(target_id: pm.id).last&.source || pm
      parent.get_deduplicated_smooch_annotations.each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
        message = parent.team.get_status_message_for_language(status, data['language'])
        unless message.blank?
          response = self.send_message_to_user(data['authorId'], message)
          self.save_smooch_response(response, parent, data['received'].to_i, 'fact_check_status', data['language'], { message: message })
          requestors_count += 1
        end
      end
      CheckNotification::InfoMessages.send('sent_message_to_requestors_on_status_change', status: pm.status_i18n, requestors_count: requestors_count) if requestors_count > 0
    end
  end
end
