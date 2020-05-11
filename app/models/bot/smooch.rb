require 'digest'

class SmoochBotDeliveryFailure < StandardError
end

class Bot::Smooch < BotUser

  check_settings

  ::ProjectMedia.class_eval do
    attr_accessor :smooch_message
  end

  ::Workflow::VerificationStatus.class_eval do
    check_workflow from: :any, to: :any, actions: :replicate_status_to_children
  end

  ::Relationship.class_eval do
    after_create do
      target = self.target
      parent = self.source
      if ::Bot::Smooch.team_has_smooch_bot_installed(target)
        s = target.annotations.where(annotation_type: 'verification_status').last&.load
        status = parent.last_verification_status
        if !s.nil? && s.status != status
          s.status = status
          s.save!
        end
        ::Bot::Smooch.delay_for(1.second).send_report_from_parent_to_child(parent.id, target.id)
      end
    end

    after_destroy do
      target = self.target
      s = target.annotations.where(annotation_type: 'verification_status').last&.load
      status = ::Workflow::Workflow.options(target, 'verification_status')[:default]
      if !s.nil? && s.status != status
        s.status = status
        s.save!
      end
    end
  end

  ::Dynamic.class_eval do
    after_save do
      if self.annotation_type == 'report_design'
        action = self.action
        self.copy_report_image_paths if action == 'save' || action =~ /publish/
        if action =~ /publish/
          ReportDesignerWorker.perform_in(1.second, self.id, action)
          self.annotated.clear_caches
        end
      end
    end
    after_save :change_smooch_user_state, if: proc { |d| d.annotation_type == 'smooch_user' }
    before_destroy :delete_smooch_cache_keys, if: proc { |d| d.annotation_type == 'smooch_user' }, prepend: true

    scope :smooch_user, -> { where(annotation_type: 'smooch_user').joins(:fields).where('dynamic_annotation_fields.field_name' => 'smooch_user_data') }

    private

    def delete_smooch_cache_keys
      uid = self.get_field_value('smooch_user_id')
      unless uid.blank?
        ["smooch:bundle:#{uid}", "smooch:last_accepted_terms:#{uid}", "smooch:banned:#{uid}"].each { |key| Rails.cache.delete(key) }
        Rails.cache.delete_matched("smooch:request:#{uid}:*")
        sm = CheckStateMachine.new(uid)
        sm.leave_human_mode if sm.state.value == 'human_mode'
      end
    end

    def change_smooch_user_state
      id = self.get_field_value('smooch_user_id')
      unless id.blank?
        sm = CheckStateMachine.new(id)
        case self.action
        when 'deactivate'
          sm.enter_human_mode
        when 'reactivate'
          sm.leave_human_mode
        when 'refresh_timeout'
          Bot::Smooch.refresh_smooch_slack_timeout(id, JSON.parse(self.action_data))
        else
          app_id = self.get_field_value('smooch_user_app_id')
          message = self.action.to_s.match(/^send (.*)$/)
          unless message.nil?
            Bot::Smooch.get_installation('smooch_app_id', app_id)
            payload = {
              '_id': Digest::MD5.hexdigest([self.action.to_s, Time.now.to_f.to_s].join(':')),
              authorId: id,
              type: 'text',
              text: message[1]
            }.with_indifferent_access
            Bot::Smooch.save_message_later(payload, app_id)
          end
        end
      end
    end
  end

  ::DynamicAnnotation::Field.class_eval do
    after_save do
      if self.field_name == 'smooch_user_slack_channel_url'
        smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_type: 'smooch_user', annotation_id: self.annotation.id).last
        value = smooch_user_data.value_json unless smooch_user_data.nil?
        a = self.annotation
        Rails.cache.write("SmoochUserSlackChannelUrl:Team:#{a.team_id}:#{value['id']}", self.value) unless value.blank?
      end
    end

    protected

    def replicate_status_to_children
      pm = self.annotation.annotated
      return unless Bot::Smooch.team_has_smooch_bot_installed(pm)
      ::Bot::Smooch.delay_for(1.second, { queue: 'smooch', retry: 0 }).replicate_status_to_children(self.annotation.annotated_id, self.value, User.current&.id, Team.current&.id)
    end
  end

  ::Version.class_eval do
    def smooch_user_slack_channel_url
      object_after = JSON.parse(self.object_after)
      return unless object_after['field_name'] == 'smooch_data'
      slack_channel_url = ''
      data = JSON.parse(object_after['value'])
      unless data.nil?
        obj = self.associated
        key = "SmoochUserSlackChannelUrl:Team:#{self.team_id}:#{data['authorId']}"
        slack_channel_url = Rails.cache.fetch(key) do
          # Retrieve URL
          get_slack_channel_url(obj, data)
        end
      end
      slack_channel_url
    end

    private

    def get_slack_channel_url(obj, data)
      # Fetch project from Smooch Bot and fallback to obj.project_id
      pid = nil
      bot = BotUser.where(login: 'smooch').last
      tbi = TeamBotInstallation.where(team_id: obj.team_id, user_id: bot&.id.to_i).last
      pid =  tbi.get_smooch_project_id unless tbi.nil?
      pid ||= obj.project_id
      smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_type: 'smooch_user')
      .where("value_json ->> 'id' = ?", data['authorId'])
      .joins("INNER JOIN annotations a ON a.annotation_type= dynamic_annotation_fields.annotation_type")
      .where("a.annotated_type = ? AND a.annotated_id = ?", 'Project', pid).uniq
      field_value = nil
      smooch_user_data.each do |f|
        slack_channel_url = DynamicAnnotation::Field.where(field_name: 'smooch_user_slack_channel_url', annotation_type: 'smooch_user', annotation_id: f.annotation.id).last
        field_value = slack_channel_url.value unless slack_channel_url.nil?
        break unless field_value.nil?
      end
      field_value
    end
  end

  TeamBotInstallation.class_eval do
    # Save Twitter token and authorization URL
    after_create do
      if self.bot_user.identifier == 'smooch'
        token = SecureRandom.hex
        self.set_smooch_authorization_token = token
        self.set_smooch_twitter_authorization_url = "#{CONFIG['checkdesk_base_url']}/api/users/auth/twitter?context=smooch&destination=#{CONFIG['checkdesk_base_url']}/api/admin/smooch_bot/#{self.id}/authorize/twitter?token=#{token}"
        self.save!
      end
    end

    # Upload custom strings to Transifex
    after_save do
      if self.bot_user.identifier == 'smooch'
        strings = {}
        self.settings.each do |key, value|
          strings[key.to_s.gsub(/^smooch_message_smooch_bot_/, '')] = value if key.to_s =~ /^smooch_message_/ && !value.blank?
        end
        ['main', 'secondary', 'query'].each do |state|
          value = self.settings.dig("smooch_state_#{state}", 'smooch_menu_message')
          strings["smooch_state_#{state}_smooch_menu_message"] = value unless value.blank?
        end
        CheckI18n.upload_custom_strings_to_transifex_in_background(self.team, 'smooch_bot', strings) unless strings.blank?
      end
    end
  end

  SMOOCH_PAYLOAD_JSON_SCHEMA = {
    type: 'object',
    required: ['trigger', 'app', 'version', 'appUser'],
    properties: {
      trigger: {
        type: 'string'
      },
      app: {
        type: 'object',
        required: ['_id'],
        properties: {
          '_id': {
            type: 'string'
          }
        }
      },
      version: {
        type: 'string'
      },
      messages: {
        type: 'array',
        items: {
          type: 'object',
          required: ['type'],
          properties: {
            type: {
              type: 'string'
            },
            text: {
              type: 'string'
            },
            mediaUrl: {
              type: 'string'
            },
            role: {
              type: 'string'
            },
            received: {
              type: 'number'
            },
            name: {
              type: ['string', nil]
            },
            authorId: {
              type: 'string'
            },
            '_id': {
              type: 'string'
            },
            source: {
              type: 'object',
              properties: {
                type: {
                  type: 'string'
                },
                integrationId: {
                  type: 'string'
                }
              }
            }
          }
        }
      },
      appUser: {
        type: 'object',
        properties: {
          '_id': {
            type: 'string'
          },
          'conversationStarted': {
            type: 'boolean'
          }
        }
      }
    }
  }

  def self.team_has_smooch_bot_installed(pm)
    bot = BotUser.where(login: 'smooch').last
    tbi = TeamBotInstallation.where(team_id: pm.team_id, user_id: bot&.id.to_i).last
    !tbi.nil? && tbi.settings.with_indifferent_access[:smooch_disabled].blank?
  end

  def self.get_installation(key, value)
    bot = BotUser.where(login: 'smooch').last
    return nil if bot.nil?
    smooch_bot_installation = nil
    TeamBotInstallation.where(user_id: bot.id).each do |installation|
      smooch_bot_installation = installation if installation.settings.with_indifferent_access[key] == value
    end
    settings = smooch_bot_installation&.settings || {}
    RequestStore.store[:smooch_bot_settings] = settings.with_indifferent_access.merge({ team_id: smooch_bot_installation&.team_id.to_i })
    smooch_bot_installation
  end

  def self.valid_request?(request)
    RequestStore.store[:smooch_bot_queue] = request.headers['X-Check-Smooch-Queue'].to_s
    key = request.headers['X-API-Key'].to_s
    installation = self.get_installation('smooch_webhook_secret', key)
    !key.blank? && !installation.nil?
  end

  def self.config
    RequestStore.store[:smooch_bot_settings]
  end

  def self.webhook(request)
    # FIXME This should be packaged as an event "invoke_webhook" + data payload
    Bot::Smooch.run(request.body.read)
  end

  def self.run(body)
    begin
      json = JSON.parse(body)
      JSON::Validator.validate!(SMOOCH_PAYLOAD_JSON_SCHEMA, json)
      case json['trigger']
      when 'message:appUser'
        json['messages'].each do |message|
          self.parse_message(message, json['app']['_id'])
        end
        true
      when 'message:delivery:failure'
        self.resend_message(json)
        true
      else
        false
      end
    rescue StandardError => e
      Rails.logger.error("[Smooch Bot] Exception for trigger #{json&.dig('trigger') || 'unknown'}: #{e.message}")
      self.notify_error(e, { bot: self.name, body: body }, RequestStore[:request])
      raise(e) if e.is_a?(AASM::InvalidTransition) # Race condition: return 500 so Smooch can retry it later
      false
    end
  end

  def self.parse_message(message, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    if sm.state.value == 'human_mode'
      self.refresh_smooch_slack_timeout(uid)
      return
    end
    self.refresh_smooch_menu_timeout(uid)
    redis = Redis.new(REDIS_CONFIG)
    key = "smooch:bundle:#{uid}"
    self.delay_for(1.second).save_user_information(app_id, uid) if redis.llen(key) == 0
    self.parse_message_based_on_state(message, app_id)
  end

  def self.parse_message_based_on_state(message, app_id)
    uid = message['authorId']
    message['language'] ||= Rails.cache.read("smooch:user_language:#{uid}")
    sm = CheckStateMachine.new(uid)
    state = sm.state.value
    case state
    when 'waiting_for_message'
      message['language'] = self.get_language(message)
      Rails.cache.write("smooch:user_language:#{uid}", message['language'])
      has_main_menu = (self.config.dig('smooch_state_main', 'smooch_menu_options').to_a.size > 0)
      if has_main_menu
        sm.start
        main_message = [self.i18n_t(:smooch_bot_greetings, { locale: message['language'] }), self.i18n_t(['smooch_bot', 'smooch_state_main', 'smooch_menu_message'], { locale: message['language'] })].join("\n\n")
        self.send_message_to_user(uid, main_message)
      else
        sm.go_to_query
        self.parse_message_based_on_state(message, app_id)
      end
    when 'main', 'secondary'
      if !self.process_menu_option(message, state)
        no_option_message = [self.i18n_t(:smooch_bot_option_not_available, { locale: message['language'] }), self.i18n_t(['smooch_bot', "smooch_state_#{state}", 'smooch_menu_message'], { locale: message['language'] })].join("\n\n")
        self.send_message_to_user(uid, no_option_message)
      end
    when 'query'
      (self.process_menu_option(message, state) && Redis.new(REDIS_CONFIG).del("smooch:bundle:#{uid}")) || self.bundle_message(message, app_id)
    end
  end

  def self.process_menu_option(message, state)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    self.config.dig("smooch_state_#{state}", 'smooch_menu_options').to_a.each do |option|
      if option['smooch_menu_option_keyword'].split(',').map(&:downcase).map(&:strip).include?(message['text'].to_s.downcase.strip)
        if option['smooch_menu_option_value'] =~ /_state$/
          new_state = option['smooch_menu_option_value'].gsub(/_state$/, '')
          sm.send("go_to_#{new_state}")
          self.send_message_to_user(uid, self.i18n_t(['smooch_bot', "smooch_state_#{new_state}", 'smooch_menu_message'], { locale: message['language'] }))
        elsif option['smooch_menu_option_value'] == 'resource'
          pmid = option['smooch_menu_project_media_id'].to_i
          pm = ProjectMedia.where(id: pmid, team_id: self.config['team_id'].to_i).last
          lang = message['language'].blank? ? 'en' : message['language']
          self.send_report_to_user(uid, {}, pm, lang)
          sm.reset
        end
        return true
      end
    end
    return false
  end

  def self.bundle_message(message, app_id)
    uid = message['authorId']
    redis = Redis.new(REDIS_CONFIG)
    key = "smooch:bundle:#{uid}"
    redis.rpush(key, message.to_json)
    self.delay_for(30.seconds, { queue: 'smooch', retry: 5 }).bundle_messages(uid, message['_id'], app_id)
  end

  def self.bundle_messages(uid, id, app_id)
    redis = Redis.new(REDIS_CONFIG)
    key = "smooch:bundle:#{uid}"
    list = redis.lrange(key, 0, redis.llen(key))
    unless list.empty?
      last = JSON.parse(list.last)
      if last['_id'] == id
        self.get_installation('smooch_app_id', app_id) if self.config.blank?
        bundle = last.clone
        text = []
        media = nil
        list.collect{ |m| JSON.parse(m) }.sort_by{ |m| m['received'].to_f }.each do |message|
          next unless self.supported_message?(message)[:type]
          if media.nil?
            media = message['mediaUrl']
            bundle['type'] = message['type']
            bundle['mediaUrl'] = media
          else
            text << message['mediaUrl'].to_s
          end
          text << message['text'].to_s
        end
        bundle['text'] = text.reject{ |t| t.blank? }.join("\n")
        self.discard_or_process_message(bundle, app_id)
        redis.del(key)
        sm = CheckStateMachine.new(uid)
        sm.reset
      end
    end
  end

  def self.resend_message(message)
    code = begin message['error']['underlyingError']['errors'][0]['code'] rescue 0 end
    self.delay_for(1.second, { queue: 'smooch', retry: 0 }).resend_message_after_window(message.to_json) if code == 470
    self.notify_error(SmoochBotDeliveryFailure.new('Could not deliver message to final user!'), message, RequestStore[:request]) if message['isFinalEvent'] && code != 470
  end

  def self.i18n_t(key, options = {})
    config = self.config || {}
    team = Team.where(id: config['team_id'].to_i).last
    fallback = key.is_a?(Array) ? config.dig(*(key - ['smooch_bot'])) : config["smooch_message_#{key}"]
    key = key.join('_') if key.is_a?(Array)
    CheckI18n.i18n_t(team, key, fallback, options)
  end

  def self.resend_message_after_window(message)
    message = JSON.parse(message)
    self.get_installation('smooch_app_id', message['app']['_id'])
    pm_id = Rails.cache.read('smooch:response:' + message['message']['_id']).to_i
    pm = ProjectMedia.where(id: pm_id).last
    unless pm.nil?
      report = pm.get_dynamic_annotation('report_design')
      if !report.nil? && report.get_field_value('state') == 'published' && self.config['smooch_template_namespace']
        fallback = report.report_design_text
        status = report.get_field_value('status_label')
        ::Bot::Smooch.send_message_to_user(message['appUser']['_id'], "&[#{fallback}](#{self.config['smooch_template_namespace']}, check_verification_results, #{status}, #{pm.embed_url})")
        return
      end
    end
    self.notify_error(SmoochBotDeliveryFailure.new('Could not deliver message to final user!'), message, RequestStore[:request]) if message['isFinalEvent']
  end

  def self.get_language(message)
    text = message['text'].to_s
    lang = text.blank? ? nil : Bot::Alegre.get_language_from_alegre(text)
    lang = 'en' if lang == 'und' || lang.blank? || !I18n.available_locales.include?(lang.to_sym)
    lang
  end

  def self.message_hash(message)
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

  def self.discard_or_process_message(message, app_id)
    if self.config['smooch_disabled']
      message['language'] = self.get_language(message)
      self.send_message_to_user(message['authorId'], ::Bot::Smooch.i18n_t(:smooch_bot_disabled, { locale: message['language'] }), {}, true)
    else
      self.process_message(message, app_id)
    end
  end

  def self.save_user_information(app_id, uid)
    self.get_installation('smooch_app_id', app_id) if self.config.blank?
    # FIXME Shouldn't we make sure this is an annotation in the right project?
    field = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: uid).last
    if field.nil?
      api_client = self.smooch_api_client
      app_id = self.config['smooch_app_id']
      api_instance = SmoochApi::AppUserApi.new(api_client)
      user = api_instance.get_app_user(app_id, uid).appUser.to_hash
      api_instance = SmoochApi::AppApi.new(api_client)
      app = api_instance.get_app(app_id)

      # This identifier is used on the Slack side in order to connect a Slack conversation to a Smooch user

      identifier = case user[:clients][0][:platform]
                   when 'whatsapp'
                     user[:clients][0][:displayName]
                   when 'messenger'
                     user[:clients][0][:info][:avatarUrl].match(/psid=([0-9]+)/)[1]
                   when 'twitter'
                     user[:clients][0][:info][:avatarUrl].match(/profile_images\/([0-9]+)\//)[1]
                   else
                     uid
                   end

      identifier = Digest::MD5.hexdigest(identifier)

      data = {
        id: uid,
        raw: user,
        identifier: identifier,
        app_name: app.app.name
      }

      a = Dynamic.new
      a.skip_check_ability = true
      a.skip_notifications = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.annotation_type = 'smooch_user'
      a.annotated_type = 'Project'
      a.annotated_id = self.get_project_id
      a.set_fields = { smooch_user_data: data.to_json, smooch_user_id: uid, smooch_user_app_id: app_id }.to_json
      a.save!
      query = { field_name: 'smooch_user_data', json: { app_name: app.app.name, identifier: identifier } }.to_json
      cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(query)
      Rails.cache.write(cache_key, DynamicAnnotation::Field.where(annotation_id: a.id, field_name: 'smooch_user_data').last&.id)
      # Cache SmoochUserSlackChannelUrl if smooch_user_slack_channel_url exist
      cache_slack_key = "SmoochUserSlackChannelUrl:Team:#{a.team_id}:#{uid}"
      if Rails.cache.read(cache_slack_key).blank?
        slack_channel_url = a.get_field_value('smooch_user_slack_channel_url')
        Rails.cache.write(cache_slack_key, slack_channel_url) unless slack_channel_url.blank?
      end
    end
  end

  def self.send_tos_if_needed(uid, lang)
    last = Rails.cache.read("smooch:last_accepted_terms:#{uid}").to_i
    if last < User.terms_last_updated_at_by_page('tos_smooch') || last < Time.now.yesterday.to_i
      self.send_message_to_user(uid, ::Bot::Smooch.i18n_t(:smooch_bot_ask_for_tos, { locale: lang, tos: CheckConfig.get('tos_smooch_url') }))
      Rails.cache.write("smooch:last_accepted_terms:#{uid}", Time.now.to_i)
    end
  end

  def self.process_message(message, app_id)
    message['language'] = self.get_language(message)

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

  def self.save_message_later_and_reply_to_user(message, app_id)
    self.save_message_later(message, app_id)
    self.send_message_to_user(message['authorId'], ::Bot::Smooch.i18n_t(:smooch_bot_message_confirmed, { locale: message['language'] }))
  end

  def self.get_text_from_message(message)
    text = message['text'][/[^\s]+\.[^\s]+/, 0].to_s.gsub(/^https?:\/\//, '')
    text = message['text'] if text.blank?
    text.downcase
  end

  def self.supported_message?(message)
    type = message['type']
    if type == 'file'
      message['mediaType'] = self.detect_media_type(message) if message['mediaType'].blank?
      m = message['mediaType'].to_s.match(/^(image|video)\//)
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
    else
      ret = { type: false, size: false }
    end
    ret
  end

  def self.send_error_message(message, is_supported)
    error_message = is_supported[:type] == false ? :smooch_bot_message_type_unsupported : :smooch_bot_message_size_unsupported
    max_size = is_supported[:m_type] == 'video' ? UploadedVideo.max_size_readable : UploadedImage.max_size_readable
    self.send_message_to_user(message['authorId'], ::Bot::Smooch.i18n_t(error_message, { locale: message['language'], max_size: max_size }))
  end

  def self.smooch_api_client
    payload = { scope: 'app' }
    jwt_header = { kid: self.config['smooch_secret_key_key_id'] }
    token = JWT.encode payload, self.config['smooch_secret_key_secret'], 'HS256', jwt_header
    config = SmoochApi::Configuration.new
    config.api_key['Authorization'] = token
    config.api_key_prefix['Authorization'] = 'Bearer'
    SmoochApi::ApiClient.new(config)
  end

  def self.send_message_to_user(uid, text, extra = {}, force = false)
    return if self.config['smooch_disabled'] && !force
    api_client = self.smooch_api_client
    api_instance = SmoochApi::ConversationApi.new(api_client)
    app_id = self.config['smooch_app_id']
    params = { 'role' => 'appMaker', 'type' => 'text', 'text' => text }.merge(extra)
    message_post_body = SmoochApi::MessagePost.new(params)
    begin
      api_instance.post_message(app_id, uid, message_post_body)
    rescue SmoochApi::ApiError => e
      Rails.logger.error("[Smooch Bot] Exception when sending message #{params.inspect}: #{e.response_body}")
      e2 = SmoochBotDeliveryFailure.new('Could not send message to Smooch user!')
      self.notify_error(e2, { smooch_app_id: app_id, uid: uid, body: params, smooch_response: e.response_body }, RequestStore[:request])
    end
  end

  def self.save_message_later(message, app_id)
    mapping = { 'siege' => 'siege' }
    queue = RequestStore.store[:smooch_bot_queue].to_s
    queue = queue.blank? ? 'smooch' : (mapping[queue] || 'smooch')
    type = (message['type'] == 'text' && !message['text'][/https?:\/\/[^\s]+/, 0].blank?) ? 'link' : message['type']
    SmoochWorker.set(queue: queue).perform_in(1.second, message.to_json, type, app_id)
  end

  def self.save_message(message_json, app_id, author = nil)
    message = JSON.parse(message_json)
    self.get_installation('smooch_app_id', app_id)
    Team.current = Team.where(id: self.config['team_id']).last
    message['project_id'] = self.get_project_id(message)

    pm = case message['type']
         when 'text'
           self.save_text_message(message)
         when 'image'
           self.save_media_message(message)
         when 'video'
           self.save_media_message(message, 'video')
         when 'file'
           message['mediaType'] = self.detect_media_type(message)
           m = message['mediaType'].to_s.match(/^(image|video)\//)
           m.nil? ? return : self.save_media_message(message, m[1])
         else
           return
         end

    return if pm.nil?

    # Remember that we received this message.
    hash = self.message_hash(message)
    Rails.cache.write("smooch:message:#{hash}", pm.id)

    # Only save the annotation for the same requester once.
    key = 'smooch:request:' + message['authorId'] + ':' + pm.id.to_s
    self.create_smooch_request(pm, message, app_id, author) if !Rails.cache.read(key)
    Rails.cache.write(key, hash)

    # If item is published (or parent item), send a report right away
    self.send_report_to_user(message['authorId'], message, pm, message['language'])
  end

  def self.create_smooch_request(pm, message, app_id, author)
    # TODO: By Sawy - Should handle User.current value
    # In this case User.current was reset by SlackNotificationWorker worker
    # Quick fix - assigning it again using pm object and reset its value at the end of creation
    current_user = User.current
    User.current = author || pm.user
    a = Dynamic.new
    a.skip_check_ability = true
    a.skip_notifications = true
    a.disable_es_callbacks = Rails.env.to_s == 'test'
    a.annotation_type = 'smooch'
    a.annotated = pm
    a.set_fields = { smooch_data: message.merge({ app_id: app_id }).to_json }.to_json
    a.save!
    User.current = current_user
  end

  def self.get_project_id(_message = nil)
    project_id = self.config['smooch_project_id'].to_i
    raise "Project ID #{project_id} does not belong to team #{self.config['team_id']}" if Project.where(id: project_id, team_id: self.config['team_id'].to_i).last.nil?
    project_id
  end

  def self.extract_url(text)
    begin
      urls = Twitter::Extractor.extract_urls(text)
      return nil if urls.blank?
      url = urls.first
      url = 'https://' + url unless url =~ /^https?:\/\//
      URI.parse(url)
      m = Link.new url: url
      m.validate_pender_result(false, true)
      if m.pender_error
        raise SecurityError if m.pender_error_code == PenderClient::ErrorCodes::UNSAFE
        nil
      else
        m.url
      end
    rescue URI::InvalidURIError
      nil
    end
  end

  def self.add_hashtags(text, pm)
    hashtags = Twitter::Extractor.extract_hashtags(text)
    return nil if hashtags.blank?

    # Only add team tags.
    TagText
      .joins('LEFT JOIN projects ON projects.team_id = tag_texts.team_id')
      .where('projects.id=? AND teamwide=? AND text IN (?)', pm.project_id, true, hashtags)
      .each do |tag|
        unless pm.annotations('tag').map(&:tag_text).include?(tag.text)
          Tag.create!(tag: tag, annotator: pm.user, annotated: pm)
        end
      end
  end

  def self.ban_user(message)
    uid = message['authorId']
    Rails.logger.info("[Smooch Bot] Banned user #{uid}")
    Rails.cache.write("smooch:banned:#{uid}", message.to_json)
  end

  def self.save_text_message(message)
    text = message['text']
    project_ids = Team.where(id: config['team_id'].to_i).last.project_ids

    begin
      url = self.extract_url(text)
      pm = nil
      if url.nil?
        pm = ProjectMedia.joins(:media).where('lower(quote) = ?', text.downcase).where('project_medias.project_id' => project_ids).last || self.create_project_media(message, 'Claim', { quote: text })
      else
        pm = ProjectMedia.joins(:media).where('medias.url' => url, 'project_medias.project_id' => project_ids).last || self.create_project_media(message, 'Link', { url: url })
      end

      self.add_hashtags(text, pm)

      pm
    rescue SecurityError
      self.ban_user(message)
      nil
    end
  end

  def self.create_project_media(message, type, extra)
    pm = ProjectMedia.create!({ project_id: message['project_id'], media_type: type, smooch_message: message }.merge(extra))
    pm.is_being_created = true
    pm
  end

  def self.detect_media_type(message)
    type = nil
    begin
      m_type = MimeMagic.by_magic(open(message['mediaUrl']))
      type = m_type.type
      unless type.nil? || type == message['mediaType']
        Rails.logger.warn "[Smooch Bot] saved file #{message['mediaUrl']} as #{type} instead of #{message['mediaType']}"
      end
    rescue
      nil
    end
    type || message['mediaType']
  end

  def self.save_media_message(message, type = 'image')
    open(message['mediaUrl']) do |f|
      text = message['text']

      data = f.read
      hash = Digest::MD5.hexdigest(data)
      filename = type == 'image' ? "#{hash}.jpeg" : "#{hash}.mp4"
      filepath = File.join(Rails.root, 'tmp', filename)
      media_type = type == 'image' ? 'UploadedImage' : 'UploadedVideo'
      File.atomic_write(filepath) { |file| file.write(data) }
      pm = ProjectMedia.joins(:media).where('medias.type' => media_type, 'medias.file' => filename, 'project_medias.project_id' => message['project_id']).last
      if pm.nil?
        m = media_type.constantize.new
        File.open(filepath) do |f2|
          m.file = f2
        end
        m.save!
        pm = ProjectMedia.create!(project_id: message['project_id'], media: m, media_type: media_type, smooch_message: message)
        pm.is_being_created = true
      end
      FileUtils.rm_f filepath

      self.add_hashtags(text, pm)

      pm
    end
  end

  def self.send_report_to_users(pm, action)
    parent = Relationship.where(target_id: pm.id).last&.source || pm
    report = parent.get_annotations('report_design').last.load
    return if report.nil?
    previous_status = report.get_field_value('previous_published_status_label')
    status = report.get_field_value('status_label')
    last_published_at = report.get_field_value('last_published').to_i
    ProjectMedia.where(id: parent.related_items_ids).each do |pm2|
      pm2.get_annotations('smooch').find_each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
        self.send_correction_to_user(data, previous_status, status, parent, annotation.created_at, last_published_at, action) unless self.config['smooch_disabled']
      end
    end
  end

  def self.send_correction_to_user(data, previous_status, status, pm, subscribed_at, last_published_at, action)
    uid = data['authorId']
    lang = data['language']
    # User received a report before
    if subscribed_at.to_i < last_published_at.to_i
      if ['publish', 'republish_and_resend'].include?(action)
        params = { locale: lang, status: status, previous_status: previous_status, url: '' }
        message = self.i18n_t(:smooch_bot_result_changed, params)
        self.send_message_to_user(uid, message)
        sleep 1
        self.send_report_to_user(uid, data, pm, lang)
      end
    else
      self.send_report_to_user(uid, data, pm, lang)
    end
  end

  def self.send_report_to_user(uid, data, pm, lang = 'en')
    parent = Relationship.where(target_id: pm.id).last&.source || pm
    report = parent.get_dynamic_annotation('report_design')
    if report&.get_field_value('state') == 'published'
      last_smooch_response = nil
      if report.get_field_value('use_introduction')
        introduction = report.report_design_introduction(data)
        params = (data['mediaUrl'] && report.get_field_value('introduction').to_s =~ /{{query_message}}/) ? { type: data['type'], mediaUrl: data['mediaUrl'] } : {}
        last_smooch_response = self.send_message_to_user(uid, introduction, params)
        sleep 1
      end
      if report.get_field_value('use_visual_card')
        last_smooch_response = self.send_message_to_user(uid, '', { type: 'image', mediaUrl: report.report_design_image_url })
        sleep 3
      end
      if report.get_field_value('use_text_message')
        last_smooch_response = self.send_message_to_user(uid, report.report_design_text)
      end
      self.send_tos_if_needed(uid, lang)
      self.save_smooch_response(last_smooch_response, parent)
    end
  end

  def self.save_smooch_response(response, pm)
    return if response.nil?
    id = response&.message&.id
    Rails.cache.write('smooch:response:' + id, pm.id) unless id.blank?
  end

  def self.send_report_from_parent_to_child(parent_id, target_id)
    parent = ProjectMedia.where(id: parent_id).last
    child = ProjectMedia.where(id: target_id).last
    return if parent.nil? || child.nil?
    child.get_annotations('smooch').find_each do |annotation|
      data = JSON.parse(annotation.load.get_field_value('smooch_data'))
      self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
      self.send_report_to_user(data['authorId'], data, parent, data['language'])
    end
  end

  def self.replicate_status_to_children(pm_id, status, uid, tid)
    pm = ProjectMedia.where(id: pm_id).last
    return if pm.nil?
    User.current = User.where(id: uid).last
    Team.current = Team.where(id: tid).last
    pm.source_relationships.joins('INNER JOIN users ON users.id = relationships.user_id').where("users.type != 'BotUser' OR users.type IS NULL").find_each do |relationship|
      target = relationship.target
      s = target.annotations.where(annotation_type: 'verification_status').last&.load
      next if s.nil? || s.status == status
      s.status = status
      s.save!
    end
    User.current = nil
    Team.current = nil
  end

  def self.refresh_smooch_slack_timeout(uid, slack_data = {})
    time = Time.now.to_i
    data = Rails.cache.read("smooch:slack:last_human_message:#{uid}") || {}
    data.merge!(slack_data.merge({ 'time' => time }))
    Rails.cache.write("smooch:slack:last_human_message:#{uid}", data)
    sm = CheckStateMachine.new(uid)
    if sm.state.value != 'human_mode'
      sm.enter_human_mode
      text = 'The bot has been de-activated for this conversation. You can now communicate directly to the user in this channel. To reactivate the bot, type `/check bot activate`. <https://intercom.help/meedan/en/articles/3365307-slack-integration|Learn about more features of the Slack integration here.>'
      Bot::Slack.delay_for(1.second).send_message_to_slack_conversation(text, slack_data['token'], slack_data['channel'])
    end
    self.delay_for(15.minutes).timeout_smooch_slack_human_conversation(uid, time)
  end

  def self.timeout_smooch_slack_human_conversation(uid, time)
    data = Rails.cache.read("smooch:slack:last_human_message:#{uid}")
    return if !data || data['time'].to_i > time
    sm = CheckStateMachine.new(uid)
    if sm.state.value == 'human_mode'
      sm.leave_human_mode
      text = 'Automated bot-message reactivated after 15 min of inactivity. <http://help.checkmedia.org/en/articles/3336466-talk-to-users-on-your-check-message-tip-line|Learn more here>.'
      Bot::Slack.send_message_to_slack_conversation(text, data['token'], data['channel'])
    end
  end

  def self.refresh_smooch_menu_timeout(uid)
    time = Time.now.to_i
    Rails.cache.write("smooch:last_message_from_user:#{uid}", time)
    self.delay_for(15.minutes).timeout_smooch_menu(uid, time)
  end

  def self.timeout_smooch_menu(uid, time)
    stored_time = Rails.cache.read("smooch:last_message_from_user:#{uid}").to_i
    return if stored_time > time
    sm = CheckStateMachine.new(uid)
    sm.reset unless ['human_mode', 'query'].include?(sm.state.value)
  end
end
