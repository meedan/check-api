require 'active_support/concern'

module SmoochMessages
  extend ActiveSupport::Concern

  module ClassMethods
    def parse_message(message, app_id, payload = nil)
      self.get_platform_from_message(message)
      uid = message['authorId']
      sm = CheckStateMachine.new(uid)
      if sm.state.value == 'human_mode'
        self.refresh_smooch_slack_timeout(uid)
        return
      end
      self.refresh_smooch_menu_timeout(message, app_id)
      redis = Redis.new(REDIS_CONFIG)
      key = "smooch:bundle:#{uid}"
      self.delay_for(1.second, { queue: 'smooch' }).save_user_information(app_id, uid, payload.to_json) if redis.llen(key) == 0
      self.parse_message_based_on_state(message, app_id)
    end

    def get_smooch_channel(message)
      # Get item channel (message type)
      channel = message.dig('source', 'type')&.upcase
      all_channels = CheckChannels::ChannelCodes.all_channels['TIPLINE']
      all_channels.keys.include?(channel) ? all_channels[channel] : nil
    end

    def get_typed_message(message, sm)
      # v1 (plain text)
      typed = message['text']
      new_state = nil
      # v2 (buttons and lists)
      unless message['payload'].blank?
        typed = nil
        payload = begin JSON.parse(message['payload']) rescue {} end
        if payload.class == Hash
          new_state = payload['state']
          sm.send("go_to_#{new_state}") if new_state && new_state != sm.state.value
          typed = payload['keyword']
        end
      end
      [typed.to_s.downcase.strip, new_state]
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
      redis.lrange(key, 0, redis.llen(key)).to_a.uniq
    end

    def bundle_contains_only_a_timeout_button_event(list, type)
      list.size == 1 && !list[0]['quotedMessage'].blank? && type == 'timeout_requests' && list[0]['payload'].blank?
    end

    def bundle_messages(uid, id, app_id, type = 'default_requests', annotated = nil, force = false, bundle = nil, reset_state = true)
      list = bundle || self.list_of_bundled_messages_from_user(uid)
      return if bundle_contains_only_a_timeout_button_event(list, type) # Don't store a request that is just a reaction to a button
      unless list.empty?
        last = JSON.parse(list.last)
        if last['_id'] == id || ['menu_options_requests'].include?(type) || force
          self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
          self.handle_bundle_messages(type, list, last, app_id, annotated, !force)
          if bundle.nil?
            self.clear_user_bundled_messages(uid)
            sm = CheckStateMachine.new(uid)
            sm.reset if reset_state && sm.state.value != 'main'
          end
        end
      end
    end

    def send_final_message_to_user(uid, text, workflow, language, event = nil)
      if self.is_v2?
        CheckStateMachine.new(uid).go_to_main
        self.send_message_to_user_with_main_menu_appended(uid, text, workflow, language, nil, event)
      else
        self.send_message_to_user(uid, text)
      end
    end

    def send_final_messages_to_user(uid, text, workflow, language, interval = 1, preview_url = true, event = nil)
      response = self.send_message_to_user(uid, text, {}, false, preview_url, event)
      if self.is_v2?
        label = self.get_string('navigation_button', language)
        CheckStateMachine.new(uid).go_to_main
        if interval > 1
          self.delay_for(interval.seconds, { queue: 'smooch' }).send_message_to_user_with_main_menu_appended(uid, label, nil, language, self.config['installation_id'])
        else
          sleep(interval)
          response = self.send_message_to_user_with_main_menu_appended(uid, label, workflow, language)
        end
      end
      response
    end

    def send_message_for_state(uid, workflow, state, language, pretext = '', event = nil)
      team = Team.find(self.config['team_id'].to_i)
      message = self.get_message_for_state(workflow, state, language, uid).to_s
      message = UrlRewriter.shorten_and_utmize_urls(message, team.get_outgoing_urls_utm_code) if team.get_shorten_outgoing_urls
      text = [pretext, message].reject{ |part| part.blank? }.join("\n\n")
      if self.is_v2?
        if self.should_ask_for_language_confirmation?(uid)
          self.ask_for_language_confirmation(workflow, language, uid)
        else
          # On v2, when we go to the "main" state, we need to show the main menu
          state == 'main' ? self.send_message_to_user_with_main_menu_appended(uid, text, workflow, language, nil, event) : self.send_message_for_state_with_buttons(uid, text, workflow, state, language)
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
        if state == 'subscription'
          team_id = self.config['team_id']
          subscribed = self.user_is_subscribed_to_newsletter?(uid, language, team_id)
          if value == 'subscription_confirmation'
            key = subscribed ? 'unsubscribe' : 'subscribe'
          elsif value == 'main_state' && subscribed # Cancel subscription
            key = 'keep_subscription'
          end
        end
        options << {
          value: { keyword: keyword }.to_json,
          label: self.get_string("#{key}_button_label", language, 20)
        }
      end
      options.size > 0 ? self.send_message_to_user_with_buttons(uid, text, options) : self.send_message_to_user(uid, text)
    end

    def get_message_for_state(workflow, state, language, uid = nil)
      message = []
      is_v2 = (self.config['smooch_version'] == 'v2')
      if state.to_s == 'main'
        message << (is_v2 ? self.get_string('navigation_button', language) : workflow['smooch_message_smooch_bot_greetings'])
        message << self.tos_message(workflow, language) unless is_v2
      end
      message << self.subscription_message(uid, language) if state.to_s == 'subscription'
      message << self.get_custom_string(["smooch_state_#{state}", 'smooch_menu_message'], language) if state != 'main' || !is_v2
      message << self.get_custom_string("#{state}_state", language) if ['search', 'search_result', 'add_more_details', 'ask_if_ready'].include?(state.to_s)
      message.reject{ |m| m.blank? }.join("\n\n")
    end

    def subscription_message(uid, language, subscribed = nil, full_message = true)
      subscribed = subscribed.nil? ? !TiplineSubscription.where(team_id: self.config['team_id'], uid: uid, language: language).last.nil? : subscribed
      status = subscribed ? self.get_string('subscribed', language) : self.get_string('unsubscribed', language)
      status = "*#{status}*"
      full_message ? self.get_custom_string('newsletter_optin_optout', language).gsub('{subscription_status}', status) : status
    end

    def send_message_if_disabled_and_return_state(uid, workflow, state)
      disabled = self.config['smooch_disabled']
      self.send_message_to_user(uid, self.get_custom_string('smooch_message_smooch_bot_disabled', workflow['smooch_workflow_language']), {}, true) if disabled
      disabled ? 'disabled' : state
    end

    # Used for incoming messages (e.g. message:appUser)
    # where full message contents available
    def get_platform_from_message(message)
      type = message.dig('source', 'type')
      platform = type ? ::Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[type].to_s : 'Unknown'
      RequestStore.store[:smooch_bot_platform] = platform
      platform
    end

    # Used for outgoing messages (e.g. message:delivery:channel) where
    # message contents are truncated
    def get_platform_from_payload(payload)
      type = payload.dig('destination', 'type')
      type ? ::Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[type].to_s : 'Unknown'
    end

    def request_platform
      RequestStore.store[:smooch_bot_platform]
    end

    def save_message_later_and_reply_to_user(message, app_id, send_message = true, type = 'default_requests')
      self.save_message_later(message, app_id, type)
      workflow = self.get_workflow(message['language'])
      uid = message['authorId']
      team = Team.find(self.config['team_id'].to_i)
      text = workflow['smooch_message_smooch_bot_message_confirmed'].to_s
      text = UrlRewriter.shorten_and_utmize_urls(text, team.get_outgoing_urls_utm_code) if team.get_shorten_outgoing_urls
      self.send_message_to_user(uid, text) if send_message && !workflow.nil?
    end

    def message_hash(message)
      hash = nil
      case message['type']
      when 'text'
        hash = Digest::MD5.hexdigest(self.get_text_from_message(message))
      when 'image', 'file'
        URI(message['mediaUrl']).open do |f|
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
      elsif RequestStore.store[:smooch_bot_provider] == 'CAPI'
        self.preprocess_capi_message(body)
      else
        JSON.parse(body)
      end
    end

    def process_message(message, app_id, send_message = true, type = 'default_requests')
      uid = message['authorId']
      message['language'] = self.get_user_language(uid)

      return if !Rails.cache.read("smooch:banned:#{uid}").nil?

      hash = self.message_hash(message)
      pm_id = Rails.cache.read("smooch:message:#{hash}")
      if pm_id.nil?
        is_supported = self.supported_message?(message)
        if is_supported.slice(:type, :size).all?{ |_k, v| v }
          self.save_message_later_and_reply_to_user(message, app_id, send_message, type)
        else
          self.send_error_message(message, is_supported)
        end
      else
        self.save_message_later_and_reply_to_user(message, app_id, send_message, type)
      end
    end

    def adjust_media_type(message)
      if message['type'] == 'file'
        message['mediaType'] = self.detect_media_type(message)
        m = message['mediaType'].to_s.match(/^(image|video|audio)\//)
        message['type'] = m[1] unless m.nil?
      end
      message
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
          bundle['type'] = message['type'] if message['type'] != 'interactive'
          bundle['mediaUrl'] = media
        end
        text << message['mediaUrl'].to_s
        text << begin JSON.parse(message['payload'])['keyword'] rescue message['text'] end
      end
      bundle['text'] = text.reject{ |t| t.blank? }.join("\n#{Bot::Smooch::MESSAGE_BOUNDARY}") # Add a boundary so we can easily split messages if needed
      self.adjust_media_type(bundle)
    end

    def bundle_list_of_messages_to_items(list, last)
      # Collect messages from list based on media files, long text and short text
      # so we have three types of messages
      # Long text (text with number of words > min_number_of_words_for_tipline_long_text)
      # Short text (text with number of words <= min_number_of_words_for_tipline_long_text)
      # Media (image, audio, video, etc)
      messages = []
      # Define a text variable to hold short text
      text = []
      list.collect{ |m| JSON.parse(m) }.sort_by{ |m| m['received'].to_f }.each do |message|
        if message['type'] == 'text'
          # Get an item for long text (message that match number of words condition)
          if message['payload'].nil?
            link_from_message = nil
            begin
              link_from_message = self.extract_url(message['text'])
            rescue SecurityError
              link_from_message = nil
            end
            messages << message if !link_from_message.blank? || ::Bot::Alegre.get_number_of_words(message['text'].to_s) > self.min_number_of_words_for_tipline_long_text
            # Text should be a link only in case we have two matched items (link and long text)
            text << (link_from_message.blank? ? message['text'] : link_from_message.url)
          end
        elsif !message['mediaUrl'].blank?
          # Get an item for each media file
          if !message['text'].blank? && ::Bot::Alegre.get_number_of_words(message['text'].to_s) > self.min_number_of_words_for_tipline_long_text
            message['caption'] = message['text']
            # Text should be a media url in case we have two matched items (media and caption)
            message['text'] = message['mediaUrl'].to_s
          else
            message['text'] = [message['text'], message['mediaUrl'].to_s].compact.join("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
          end
          text << message['text']
          messages << self.adjust_media_type(message)
        end
      end
      # Attach text to exising messages and return all messages
      self.attach_text_to_messages(text, messages, last)
    end

    def attach_text_to_messages(text, messages, last)
      # collect all text in right order and add a boundary so we can easily split messages if needed
      all_text = text.reject{ |t| t.blank? }.join("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
      if messages.blank?
        # No messages exist (this happens when all messages are short text)
        # So will create a new message of type text and assign short text to it
        message = last.clone
        message['type'] = 'text'
        message['text'] = all_text
        messages << message
      else
        # Attach all existing text (media text, long text and short text) to each item
        messages.each do |raw|
          # Define a new key `request_body` so we can append all text to request body
          raw['request_body'] = all_text
        end
      end
      messages
    end

    def handle_bundle_messages(type, list, last, app_id, annotated, send_message = true)
      messages = self.bundle_list_of_messages_to_items(list, last)
      messages.each do |message|
        if ['default_requests', 'irrelevant_search_result_requests'].include?(type)
          self.process_message(message, app_id, send_message, type)
        end
        if ['timeout_requests', 'menu_options_requests', 'resource_requests', 'relevant_search_result_requests', 'timeout_search_requests'].include?(type)
          key = "smooch:banned:#{message['authorId']}"
          if Rails.cache.read(key).nil?
            [annotated].flatten.uniq.each_with_index { |a, i| self.save_message_later(message, app_id, type, a, i * 60) }
          end
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

    def save_message_later(message, app_id, request_type = 'default_requests', annotated = nil, interval = 0)
      mapping = { 'siege' => 'siege' }
      queue = RequestStore.store[:smooch_bot_queue].to_s
      queue = queue.blank? ? 'smooch_priority' : (mapping[queue] || 'smooch_priority')
      type = (message['type'] == 'text' && !message['text'][/https?:\/\/[^\s]+/, 0].blank?) ? 'link' : message['type']
      associated_id = annotated&.id
      associated_class = annotated.class.name
      SmoochWorker.set(queue: queue).perform_in(1.second + interval.seconds, message.to_json, type, app_id, request_type, associated_id, associated_class)
    end

    def default_archived_flag
      team_id = self.config['team_id'].to_i
      Bot::Alegre.team_has_alegre_bot_installed?(team_id) ? CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS : CheckArchivedFlags::FlagCodes::NONE
    end

    def save_message(message_json, app_id, author = nil, request_type = 'default_requests', associated_id = nil, associated_class = nil)
      # associated: is the the "first media" and will be the source of the Relationship
      # associated_obj: is used for TiplineRequest (smooch_resource_id field)
      message = JSON.parse(message_json)
      return if TiplineRequest.where(smooch_message_id: message['_id']).exists?
      associated_obj = nil
      associated_obj = associated_class.constantize.where(id: associated_id).last unless associated_id.nil?
      self.get_installation(self.installation_setting_id_keys, app_id)
      Team.current = Team.find self.config['team_id'].to_i
      ApplicationRecord.transaction do
        associated = nil
        if ['default_requests', 'timeout_requests', 'irrelevant_search_result_requests'].include?(request_type)
          message['archived'] = ['default_requests', 'irrelevant_search_result_requests'].include?(request_type) ? self.default_archived_flag : CheckArchivedFlags::FlagCodes::UNCONFIRMED
          associated = self.create_project_media_from_message(message)
        elsif ['menu_options_requests', 'resource_requests'].include?(request_type)
          associated = associated_obj
        elsif ['relevant_search_result_requests', 'timeout_search_requests'].include?(request_type)
          message['archived'] = (request_type == 'relevant_search_result_requests' ? self.default_archived_flag : CheckArchivedFlags::FlagCodes::UNCONFIRMED)
          associated = self.create_project_media_from_message(message)
        end
        unless associated.nil?
          self.smooch_post_save_message_actions(message, associated, app_id, author, request_type, associated_obj)
          self.smooch_relate_items_for_same_message(message, associated, app_id, author, request_type, associated_obj)
        end
      end
    end

    def smooch_post_save_message_actions(message, associated, app_id, author, request_type, associated_obj)
      # Remember that we received this message.
      hash = self.message_hash(message)
      Rails.cache.write("smooch:message:#{hash}", associated.id)
      self.smooch_save_tipline_request(message, associated, app_id, author, request_type, associated_obj)
      # If item is published (or parent item), send a report right away
      self.get_platform_from_message(message)
      self.send_report_to_user(message['authorId'], message, associated, message['language'], 'fact_check_report') if self.should_try_to_send_report?(request_type, associated)
    end

    def smooch_relate_items_for_same_message(message, associated, app_id, author, request_type, associated_obj)
      return unless associated.is_a?(ProjectMedia)
      if !message['caption'].blank?
        # Check if message contains caption then create an item and force relationship
        self.relate_item_and_text(message, associated, app_id, author, request_type, associated_obj, Relationship.confirmed_type)
      elsif message['type'] == 'text' && associated.class.name == 'ProjectMedia' && associated.media.type == 'Link'
        # Check if message of type text contain a link and long text
        # Text words equal the number of words - 1(which is the link size)
        text_words = ::Bot::Alegre.get_number_of_words(message['text']) - 1
        if text_words > self.min_number_of_words_for_tipline_long_text
          # Remove link from text
          link = self.extract_url(message['text'])
          if link && link.respond_to?(:url)
            message['text'] = message['text'].remove(link.url)
          end
          self.relate_item_and_text(message, associated, app_id, author, request_type, associated_obj, Relationship.confirmed_type)
        end
      end
    end

    def relate_item_and_text(message, associated, app_id, author, request_type, associated_obj, relationship_type)
      message['_id'] = SecureRandom.hex
      message['type'] = 'text'
      message['text'] = message['caption'] unless message['caption'].nil?
      message['request_body'] = message['text']
      message.delete('caption')
      message.delete('mediaUrl')
      target = self.create_project_media_from_message(message)
      unless target.nil?
        smooch_post_save_message_actions(message, target, app_id, author, request_type, associated_obj)
        Relationship.create_unless_exists(associated.id, target.id, relationship_type)
      end
    end

    def smooch_save_tipline_request(message, associated, app_id, author, request_type, associated_obj)
      text = message['text']
      message['text'] = message['request_body'] unless message['request_body'].blank?
      message.delete('request_body')
      fields = { smooch_data: message.merge({ app_id: app_id }) }
      result = self.smooch_api_get_messages(app_id, message['authorId'])
      fields[:smooch_conversation_id] = result.conversation.id unless result.nil? || result.conversation.nil?
      fields[:smooch_message_id] = message['_id']
      fields[:smooch_request_type] = request_type
      fields[:smooch_resource_id] = associated_obj.id if request_type == 'resource_requests' && !associated_obj.nil?
      self.create_tipline_requests(associated, author, fields)
      # Update channel values for ProjectMedia items
      if associated.class.name == 'ProjectMedia'
        channel_value = self.get_smooch_channel(message)
        unless channel_value.blank?
          others = associated.channel.with_indifferent_access[:others] || []
          associated.channel[:others] = others.concat([channel_value]).uniq
          associated.skip_check_ability = true
          associated.save!
        end
      end
      # Back message text to original one
      message['text'] = text
    end

    def create_tipline_requests(associated, author, fields)
      # TODO: By Sawy - Should handle User.current value
      # In this case User.current was reset by SlackNotificationWorker worker
      # Quick fix - assigning it again using annotated object and reset its value at the end of creation
      current_user = User.current
      User.current = author
      User.current = associated.user if User.current.nil? && associated.respond_to?(:user)
      fields = fields.with_indifferent_access
      tr = TiplineRequest.new
      tr.associated = associated
      tr.skip_check_ability = true
      tr.skip_notifications = true
      tr.disable_es_callbacks = Rails.env.to_s == 'test'
      fields.each do |k, v|
        tr.send("#{k}=", v) if tr.respond_to?("#{k}=")
      end
      begin
        tr.save!
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.info('[Smooch Bot] Not storing tipline request because it already exists.')
      end
      User.current = current_user
    end

    def should_try_to_send_report?(request_type, annotated)
      ['default_requests', 'irrelevant_search_result_requests'].include?(request_type) && (annotated.respond_to?(:is_being_created) && !annotated.is_being_created)
    end

    def send_message_on_status_change(pm_id, status, request_actor_session_id = nil)
      RequestStore[:actor_session_id] = request_actor_session_id unless request_actor_session_id.nil?
      pm = ProjectMedia.find_by_id(pm_id)
      return if pm.nil?
      requestors_count = 0
      parent = Relationship.where(target_id: pm.id).last&.source || pm
      parent.get_deduplicated_tipline_requests.each do |tr|
        data = tr.smooch_data
        self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
        message = parent.team.get_status_message_for_language(status, data['language'])
        unless message.blank?
          response = self.send_message_to_user(data['authorId'], message, {}, false, true, 'status_change')
          self.save_smooch_response(response, parent, data['received'].to_i, 'fact_check_status', data['language'], { message: message })
          requestors_count += 1
        end
      end
      CheckNotification::InfoMessages.send('sent_message_to_requestors_on_status_change', status: pm.status_i18n, requestors_count: requestors_count) if requestors_count > 0
    end

    def send_message_to_user_on_timeout(uid, language)
      sm = CheckStateMachine.new(uid)
      redis = Redis.new(REDIS_CONFIG)
      user_messages_count = redis.llen("smooch:bundle:#{uid}")
      message = self.get_custom_string(:timeout, language)
      self.send_message_to_user(uid, message, {}, false, true, 'timeout') if user_messages_count > 0 && sm.state.value != 'main'
      sm.reset
    end

    def reply_to_request_with_custom_message(request, message)
      data = request.smooch_data
      team = Team.find_by_id(request.team_id)
      self.send_custom_message_to_user(team, request.tipline_user_uid, data['received'], message, request.language)
    end

    def send_custom_message_to_user(team, uid, timestamp, message, language)
      platform = self.get_user_platform(uid)
      RequestStore.store[:smooch_bot_platform] = platform
      tbi = TeamBotInstallation.where(team: team, user: BotUser.smooch_user).last
      Bot::Smooch.get_installation('team_bot_installation_id', tbi&.id) { |i| i.id == tbi&.id }
      date = I18n.l(Time.at(timestamp), locale: language, format: :short)
      message = self.format_template_message('custom_message', [date, message.to_s.gsub(/\s+/, ' ')], nil, message, language, nil, true) if platform == 'WhatsApp'
      response = self.send_message_to_user(uid, message, {}, false, true, 'custom_message')
      success = (response && response.code.to_i < 400)
      success
    end

    def min_number_of_words_for_tipline_long_text
      # Define a min number of words to create a media
      CheckConfig.get('min_number_of_words_for_tipline_long_text') || CheckConfig.get('min_number_of_words_for_tipline_submit_shortcut', 10, :integer)
    end
  end
end
