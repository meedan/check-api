require 'digest'

class SmoochBotDeliveryFailure < StandardError
end

class Bot::Smooch < BotUser

  MESSAGE_BOUNDARY = "\u2063"

  check_settings

  include SmoochMessages
  include SmoochResources
  include SmoochTos

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
        end
      end
    end
    after_save do
      if self.annotation_type == 'smooch_user'
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
      Concurrent::Future.execute(executor: POOL) do
        object_after = JSON.parse(self.object_after)
        return unless object_after['field_name'] == 'smooch_data'
        slack_channel_url = ''
        data = JSON.parse(object_after['value'])
        unless data.nil?
          key = "SmoochUserSlackChannelUrl:Team:#{self.team_id}:#{data['authorId']}"
          slack_channel_url = Rails.cache.read(key)
          if slack_channel_url.blank?
            obj = self.associated
            slack_channel_url = get_slack_channel_url(obj, data)
            Rails.cache.write(key, slack_channel_url) unless slack_channel_url.blank?
          end
        end
        slack_channel_url
      end
    end

    def smooch_user_external_identifier
      Concurrent::Future.execute(executor: POOL) do
        object_after = JSON.parse(self.object_after)
        return '' unless object_after['field_name'] == 'smooch_data'
        data = JSON.parse(object_after['value'])
        Rails.cache.fetch("smooch:user:external_identifier:#{data['authorId']}") do
          field = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: data['authorId']).last
          return '' if field.nil?
          user = JSON.parse(field.annotation.load.get_field_value('smooch_user_data')).with_indifferent_access[:raw][:clients][0]
          case user[:platform]
          when 'whatsapp'
            user[:displayName]
          when 'twitter'
            '@' + user[:raw][:screen_name]
          else
            ''
          end
        end
      end
    end

    def smooch_report_received_at
      Concurrent::Future.execute(executor: POOL) do
        begin
          self.item.annotation.load.get_field_value('smooch_report_received').to_i
        rescue
          nil
        end
      end
    end

    def smooch_report_update_received_at
      Concurrent::Future.execute(executor: POOL) do
        begin
          field = self.item.annotation.load.get_field('smooch_report_received')
          field.created_at != field.updated_at ? field.value.to_i : nil
        rescue
          nil
        end
      end
    end

    private

    def get_slack_channel_url(obj, data)
      slack_channel_url = nil
      # Fetch project from Smooch Bot and fallback to obj.project_id
      pid = nil
      bot = BotUser.where(login: 'smooch').last
      tbi = TeamBotInstallation.where(team_id: obj.team_id, user_id: bot&.id.to_i).last
      pid =  tbi.get_smooch_project_id unless tbi.nil?
      pid ||= obj.project_id
      smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_data', annotation_type: 'smooch_user')
      .where("value_json ->> 'id' = ?", data['authorId'])
      .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
      .where("a.annotated_type = ? AND a.annotated_id = ?", 'Project', pid).last
      unless smooch_user_data.nil?
        field_value = DynamicAnnotation::Field.where(field_name: 'smooch_user_slack_channel_url', annotation_type: 'smooch_user', annotation_id: smooch_user_data.annotation_id).last
        slack_channel_url = field_value.value unless field_value.nil?
      end
      slack_channel_url
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
      when 'message:delivery:user'
        self.user_received_report(json)
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

  def self.get_workflow(language = nil)
    team = Team.find(self.config['team_id'])
    default_language = team.default_language
    language ||= default_language
    workflow = nil
    default_workflow = nil
    self.config['smooch_workflows'].each do |w|
      default_workflow = w if w['smooch_workflow_language'] == default_language
      workflow = w if w['smooch_workflow_language'] == language
    end
    workflow || default_workflow
  end

  def self.get_user_language(message, state = nil)
    uid = message['authorId']
    team = Team.find(self.config['team_id'])
    default_language = team.default_language
    supported_languages = team.get_languages || ['en']
    user_language = Rails.cache.fetch("smooch:user_language:#{uid}") do
      language = default_language
      language = self.get_language(message, language) if state == 'waiting_for_message'
      language
    end
    supported_languages.include?(user_language) ? user_language : default_language
  end

  def self.parse_message_based_on_state(message, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    state = sm.state.value
    language = self.get_user_language(message, state)
    workflow = self.get_workflow(language)
    message['language'] = language
    case state
    when 'waiting_for_message'
      self.bundle_message(message)
      has_main_menu = (workflow.dig('smooch_state_main', 'smooch_menu_options').to_a.size > 0)
      if has_main_menu
        sm.start
        main_message = [workflow['smooch_message_smooch_bot_greetings'], self.get_message_for_state(workflow, 'main', language)].join("\n\n")
        self.send_message_to_user(uid, main_message)
      else
        self.clear_user_bundled_messages(uid)
        sm.go_to_query
        self.parse_message_based_on_state(message, app_id)
      end
    when 'main', 'secondary'
      if !self.process_menu_option(message, state, app_id)
        no_option_message = [workflow['smooch_message_smooch_bot_option_not_available'], self.get_message_for_state(workflow, state, language)].join("\n\n")
        self.send_message_to_user(uid, no_option_message)
      end
    when 'query'
      (self.process_menu_option(message, state, app_id) && self.clear_user_bundled_messages(uid)) ||
        self.delay_for(15.seconds, { queue: 'smooch_ping', retry: false }).bundle_messages(message['authorId'], message['_id'], app_id)
    end
  end

  def self.get_message_for_state(workflow, state, language)
    message = []
    message << self.tos_message(workflow, language) if state.to_s == 'main'
    message << workflow.dig("smooch_state_#{state}", 'smooch_menu_message')
    message.join("\n\n")
  end

  def self.process_menu_option(message, state, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    language = self.get_user_language(message, state)
    workflow = self.get_workflow(language)
    typed = message['text'].to_s.downcase.strip
    if self.should_send_tos?(state, typed)
      self.send_tos_to_user(workflow, uid, language)
      self.bundle_message(message)
      sm.reset
      return true
    end
    workflow.dig("smooch_state_#{state}", 'smooch_menu_options').to_a.each do |option|
      if option['smooch_menu_option_keyword'].split(',').map(&:downcase).map(&:strip).include?(typed)
        if option['smooch_menu_option_value'] =~ /_state$/
          self.bundle_message(message)
          new_state = option['smooch_menu_option_value'].gsub(/_state$/, '')
          self.delay_for(15.seconds, { queue: 'smooch_ping', retry: false }).bundle_messages(uid, message['_id'], app_id) if new_state == 'query'
          sm.send("go_to_#{new_state}")
          self.send_message_to_user(uid, self.get_message_for_state(workflow, new_state, language))
        elsif option['smooch_menu_option_value'] == 'resource'
          pmid = option['smooch_menu_project_media_id'].to_i
          pm = ProjectMedia.where(id: pmid, team_id: self.config['team_id'].to_i).last
          self.send_report_to_user(uid, {}, pm, language)
          sm.reset
          self.bundle_message(message)
          self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'menu_options_requests', pm)
        elsif option['smooch_menu_option_value'] == 'custom_resource'
          sm.reset
          resource = self.send_resource_to_user(uid, workflow, option)
          self.bundle_message(message)
          self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'resource_requests', resource)
        elsif option['smooch_menu_option_value'] =~ /^[a-z]{2}$/
          Rails.cache.write("smooch:user_language:#{uid}", option['smooch_menu_option_value'])
          sm.send('go_to_main')
          workflow = self.get_workflow(option['smooch_menu_option_value'])
          self.bundle_message(message)
          self.send_message_to_user(uid, self.get_message_for_state(workflow, 'main', option['smooch_menu_option_value']))
        end
        return true
      end
    end
    self.bundle_message(message)
    return false
  end

  def self.clear_user_bundled_messages(uid)
    Redis.new(REDIS_CONFIG).del("smooch:bundle:#{uid}")
  end

  def self.handle_bundle_messages(type, list, last, app_id, annotated)
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
    bundle['text'] = text.reject{ |t| t.blank? }.join("\n#{MESSAGE_BOUNDARY}") # Add a boundary so we can easily split messages if needed
    if type == 'default_requests'
      self.discard_or_process_message(bundle, app_id)
    elsif ['timeout_requests', 'menu_options_requests', 'resource_requests'].include?(type)
      key = "smooch:banned:#{bundle['authorId']}"
      self.save_message_later(bundle, app_id, type, annotated) if Rails.cache.read(key).nil?
    end
  end

  def self.template_locale_options(team_slug = nil)
    team = team_slug.nil? ? Team.current : Team.where(slug: team_slug).last
    languages = team&.get_languages
    languages.blank? ? ['en'] : languages
  end

  # https://docs.smooch.io/guide/whatsapp#shorthand-syntax
  def self.format_template_message(template_name, placeholders, image, fallback, language)
    namespace = self.config['smooch_template_namespace']
    return '' if namespace.blank?
    template = self.config["smooch_template_name_for_#{template_name}"] || template_name
    default_language = Team.where(id: self.config['team_id'].to_i).last&.default_language
    locale = (!language.blank? && [self.config['smooch_template_locales']].flatten.include?(language)) ? language : default_language
    data = { namespace: namespace, template: template, fallback: fallback, language: locale }
    data['header_image'] = image unless image.blank?
    output = ['&((']
    data.each do |key, value|
      output << "#{key}=[[#{value}]]"
    end
    placeholders.each do |placeholder|
      output << "body_text=[[#{placeholder.gsub(/\s+/, ' ')}]]"
    end
    output << '))&'
    output.join('')
  end

  def self.user_received_report(message)
    self.get_installation('smooch_app_id', message['app']['_id'])
    original = Rails.cache.read('smooch:original:' + message['message']['_id'])
    unless original.blank?
      original = JSON.parse(original)
      if original['fallback_template'] =~ /report/
        f = DynamicAnnotation::Field.joins(:annotation).where(field_name: 'smooch_data', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => original['project_media_id']).where("value_json ->> 'authorId' = ?", message['appUser']['_id']).first
        unless f.nil?
          a = f.annotation.load
          a.set_fields = { smooch_report_received: Time.now.to_i }.to_json
          a.save!
        end
      end
    end
  end

  def self.resend_message_after_window(message)
    message = JSON.parse(message)
    self.get_installation('smooch_app_id', message['app']['_id'])

    # Exit if there is no template namespace
    return false if self.config['smooch_template_namespace'].blank?

    original = Rails.cache.read('smooch:original:' + message['message']['_id'])

    # This is a report that was created or updated, or a message send by a rule action
    unless original.blank?
      original = JSON.parse(original)
      return self.resend_report_after_window(message, original) if original['fallback_template'] =~ /report/
      return self.resend_rules_message_after_window(message, original) if original['fallback_template'] == 'fact_check_status'
    end

    # A message sent from Slack
    return self.resend_slack_message_after_window(message)
  end

  def self.resend_rules_message_after_window(message, original)
    template = original['fallback_template']
    language = self.get_user_language(message)
    query_date = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
    placeholders = [query_date, original['message']]
    fallback = original['message']
    self.send_message_to_user(message['appUser']['_id'], self.format_template_message(template, placeholders, nil, fallback, language))
    true
  end

  def self.resend_report_after_window(message, original)
    pm = ProjectMedia.where(id: original['project_media_id']).last
    report = pm&.get_dynamic_annotation('report_design')
    if report&.get_field_value('state') == 'published'
      template = original['fallback_template']
      language = self.get_user_language({ 'authorId' => message['appUser']['_id'] })
      query_date = I18n.l(Time.at(original['query_date'].to_i), locale: language, format: :short)
      text = report.report_design_field_value('use_text_message', language) ? report.report_design_text(language).to_s : nil
      image = report.report_design_field_value('use_visual_card', language) ? report.report_design_image_url(language).to_s : nil
      last_smooch_response = self.send_message_to_user(message['appUser']['_id'], self.format_template_message("#{template}_image_only", [query_date], image, image, language)) unless image.blank?
      last_smooch_response = self.send_message_to_user(message['appUser']['_id'], self.format_template_message("#{template}_text_only", [query_date, text], nil, text, language)) unless text.blank?
      self.save_smooch_response(last_smooch_response, pm, query_date, 'fact_check_report', language)
      return true
    end
    false
  end

  def self.resend_slack_message_after_window(message)
    result = self.smooch_api_get_messages(message['app']['_id'], message['appUser']['_id'], { after: (message['timestamp'].to_i - 120) })
    return if result.nil?
    result.messages.each do |m|
      if m.source&.type == 'slack' && m.id == message['message']['_id']
        language = self.get_user_language({ 'authorId' => message['appUser']['_id'] })
        date = Rails.cache.read("smooch:last_message_from_user:#{message['appUser']['_id']}").to_i || Time.now.to_i
        query_date = I18n.l(Time.at(date), locale: language, format: :short)
        self.send_message_to_user(message['appUser']['_id'], self.format_template_message('more_information_needed_text_only', [query_date, m.text], nil, m.text, language))
        return true
      end
    end
    false
  end

  def self.smooch_api_get_messages(app_id, user_id, opts = {})
    result = nil
    api_client = self.smooch_api_client
    api_instance = SmoochApi::ConversationApi.new(api_client)
    begin
      result = api_instance.get_messages(app_id, user_id, opts)
    rescue StandardError => e
      Rails.logger.error("[Smooch Bot] Exception for get messages : #{e.message}")
    end
    result
  end

  def self.get_language(message, fallback_language = 'en')
    text = message['text'].to_s
    lang = text.blank? ? nil : Bot::Alegre.get_language_from_alegre(text)
    lang = fallback_language if lang == 'und' || lang.blank? || !I18n.available_locales.include?(lang.to_sym)
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

  def self.save_message_later_and_reply_to_user(message, app_id)
    self.save_message_later(message, app_id)
    workflow = self.get_workflow(message['language'])
    self.send_message_to_user(message['authorId'], workflow['smooch_message_smooch_bot_message_confirmed'])
  end

  def self.get_text_from_message(message)
    text = message['text'][/[^\s]+\.[^\s]+/, 0].to_s.gsub(/^https?:\/\//, '')
    text = message['text'] if text.blank?
    text.downcase
  end

  def self.send_error_message(message, is_supported)
    max_size = "Uploaded#{is_supported[:m_type].camelize}".constantize.max_size_readable
    workflow = self.get_workflow(message['language'])
    error_message = is_supported[:type] == false ? workflow['smooch_message_smooch_bot_message_type_unsupported'] : I18n.t(:smooch_bot_message_size_unsupported, { max_size: max_size, locale: message['language'] })
    self.send_message_to_user(message['authorId'], error_message)
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
    # An error is raised by Smooch API if we set "preview_url: true" and there is no URL in the "text" parameter
    if text.to_s.match(/https?:\/\//)
      params.merge!({
        override: {
          whatsapp: {
            payload: {
              preview_url: true,
              type: 'text',
              text: {
                body: text
              }
            }
          }
        }
      })
    end
    return if params['type'] == 'text' && params['text'].blank?
    message_post_body = SmoochApi::MessagePost.new(params)
    begin
      api_instance.post_message(app_id, uid, message_post_body)
    rescue SmoochApi::ApiError => e
      Rails.logger.error("[Smooch Bot] Exception when sending message #{params.inspect}: #{e.response_body}")
      e2 = SmoochBotDeliveryFailure.new('Could not send message to Smooch user!')
      self.notify_error(e2, { smooch_app_id: app_id, uid: uid, body: params, smooch_response: e.response_body }, RequestStore[:request])
      nil
    end
  end

  def self.create_project_media_from_message(message)
    pm =
      if message['type'] == 'text'
        self.save_text_message(message)
      else
        self.save_media_message(message)
      end
    # update archived column
    if !pm.nil? && pm.archived != CheckArchivedFlags::FlagCodes::NONE && message['archived'] == CheckArchivedFlags::FlagCodes::NONE
      pm.archived = CheckArchivedFlags::FlagCodes::NONE
      pm.save!
    end
    pm
  end

  def self.create_smooch_request(annotated, message, app_id, author, request_type)
    fields = { smooch_data: message.merge({ app_id: app_id }).to_json }
    result = self.smooch_api_get_messages(app_id, message['authorId'])
    fields[:smooch_conversation_id] = result.conversation.id unless result.nil? || result.conversation.nil?
    RequestStore.store[:skip_cached_field_update] = true if ['timeout_requests', 'resource_requests'].include?(request_type)
    self.create_smooch_annotations(annotated, author, fields)
  end

  def self.create_smooch_resources_and_type(annotated, annotated_obj, author, request_type)
    fields = { smooch_request_type: request_type }
    fields[:smooch_resource_id] = annotated_obj.id if request_type == 'resource_requests' && !annotated_obj.nil?
    self.create_smooch_annotations(annotated, author, fields)
  end

  def self.create_smooch_annotations(annotated, author, fields)
    # TODO: By Sawy - Should handle User.current value
    # In this case User.current was reset by SlackNotificationWorker worker
    # Quick fix - assigning it again using annotated object and reset its value at the end of creation
    current_user = User.current
    User.current = author
    User.current = annotated.user if User.current.nil? && annotated.respond_to?(:user)
    a = Dynamic.where(annotation_type: 'smooch', annotated_id: annotated.id, annotated_type: annotated.class.name).last
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

  def self.get_project_id(_message = nil)
    project_id = self.config['smooch_project_id'].to_i
    raise "Project ID #{project_id} does not belong to team #{self.config['team_id']}" if Project.where(id: project_id, team_id: self.config['team_id'].to_i).last.nil?
    project_id
  end

  def self.extract_url(text)
    begin
      urls = Twitter::Extractor.extract_urls(text)
      return nil if urls.blank?
      urls_to_ignore = self.config['smooch_urls_to_ignore'].to_s.split(/\s+/)
      url = urls.reject{ |u| urls_to_ignore.include?(u) }.first
      return nil if url.blank?
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

  def self.extract_claim(text)
    claim = ''
    text.split(MESSAGE_BOUNDARY).each do |part|
      claim = part.chomp if part.size > claim.size
    end
    claim
  end

  def self.add_hashtags(text, pm)
    hashtags = Twitter::Extractor.extract_hashtags(text)
    return nil if hashtags.blank?

    # Only add team tags.
    TagText.where("team_id = ? AND text IN (?)", pm.team_id, hashtags).each do |tag|
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
    team_id = Team.where(id: config['team_id'].to_i).last

    begin
      url = self.extract_url(text)
      pm = nil
      extra = {}
      if url.nil?
        claim = self.extract_claim(text)
        extra = { quote: claim }
        pm = ProjectMedia.joins(:media).where('lower(quote) = ?', claim.downcase).where('project_medias.team_id' => team_id).last
      else
        extra = { url: url }
        pm = ProjectMedia.joins(:media).where('medias.url' => url, 'project_medias.team_id' => team_id).last
      end

      if pm.nil?
        type = url.nil? ? 'Claim' : 'Link'
        pm = self.create_project_media(message, type, extra)
      end

      self.add_hashtags(text, pm)

      pm
    rescue SecurityError
      self.ban_user(message)
      nil
    end
  end

  def self.create_project_media(message, type, extra)
    extra.merge!({ archived: message['archived'] })
    pm = ProjectMedia.create!({ add_to_project_id: message['project_id'], media_type: type, smooch_message: message }.merge(extra))
    pm.is_being_created = true
    pm
  end

  def self.detect_media_type(message)
    type = nil
    begin
      headers = {}
      url = URI(message['mediaUrl'])
      Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
        headers = http.head(url.path).to_hash
      end
      m_type = headers['content-type'].first
      type = m_type.split(';').first
      unless type.nil? || type == message['mediaType']
        Rails.logger.warn "[Smooch Bot] saved file #{message['mediaUrl']} as #{type} instead of #{message['mediaType']}"
      end
    rescue
      nil
    end
    type || message['mediaType']
  end

  def self.save_media_message(message)
    if message['type'] == 'file'
      message['mediaType'] = self.detect_media_type(message)
      m = message['mediaType'].to_s.match(/^(image|video|audio)\//)
      message['type'] = m[1] unless  m.nil?
    end
    allowed_types = { 'image' => 'jpeg', 'video' => 'mp4', 'audio' => 'mp3' }
    return unless allowed_types.keys.include?(message['type'])

    open(message['mediaUrl']) do |f|
      text = message['text']

      data = f.read
      hash = Digest::MD5.hexdigest(data)
      filename = "#{hash}.#{allowed_types[message['type']]}"
      filepath = File.join(Rails.root, 'tmp', filename)
      media_type = "Uploaded#{message['type'].camelize}"
      File.atomic_write(filepath) { |file| file.write(data) }
      pm = ProjectMedia.joins(:media).joins(:project_media_projects).where('medias.type' => media_type, 'medias.file' => filename, 'project_media_projects.project_id' => message['project_id']).last
      if pm.nil?
        m = media_type.constantize.new
        File.open(filepath) do |f2|
          m.file = f2
        end
        m.save!
        pm = ProjectMedia.create!(add_to_project_id: message['project_id'], archived: message['archived'], media: m, media_type: media_type, smooch_message: message)
        pm.is_being_created = true
      end
      FileUtils.rm_f filepath

      self.add_hashtags(text, pm)

      pm
    end
  end

  def self.send_report_to_users(pm, action)
    parent = Relationship.where(target_id: pm.id).last&.source || pm
    report = parent.get_annotations('report_design').last&.load
    return if report.nil?
    last_published_at = report.get_field_value('last_published').to_i
    ProjectMedia.where(id: parent.related_items_ids).each do |pm2|
      pm2.get_annotations('smooch').find_each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
        self.send_correction_to_user(data, parent, annotation.created_at, last_published_at, action, report.get_field_value('published_count').to_i) unless self.config['smooch_disabled']
      end
    end
  end

  def self.send_correction_to_user(data, pm, subscribed_at, last_published_at, action, published_count = 0)
    uid = data['authorId']
    lang = data['language']
    # User received a report before
    if subscribed_at.to_i < last_published_at.to_i && published_count > 0
      if ['publish', 'republish_and_resend'].include?(action)
        workflow = self.get_workflow(lang)
        message = workflow['smooch_message_smooch_bot_result_changed']
        self.send_message_to_user(uid, message) unless message.blank?
        sleep 1
        self.send_report_to_user(uid, data, pm, lang, 'fact_check_report_updated')
      end
    # First report
    else
      self.send_report_to_user(uid, data, pm, lang, 'fact_check_report')
    end
  end

  def self.send_report_to_user(uid, data, pm, lang = 'en', fallback_template = nil)
    parent = Relationship.where(target_id: pm.id).last&.source || pm
    report = parent.get_dynamic_annotation('report_design')
    if report&.get_field_value('state') == 'published' && parent.archived == CheckArchivedFlags::FlagCodes::NONE
      last_smooch_response = nil
      if report.report_design_field_value('use_introduction', lang)
        introduction = report.report_design_introduction(data, lang)
        last_smooch_response = self.send_message_to_user(uid, introduction)
        sleep 1
      end
      if report.report_design_field_value('use_visual_card', lang)
        last_smooch_response = self.send_message_to_user(uid, '', { 'type' => 'image', 'mediaUrl' => report.report_design_image_url(lang) })
        sleep 3
      end
      if report.report_design_field_value('use_text_message', lang)
        last_smooch_response = self.send_message_to_user(uid, report.report_design_text(lang))
      end
      self.save_smooch_response(last_smooch_response, parent, data['received'], fallback_template, lang)
    end
  end

  def self.save_smooch_response(response, pm, query_date, fallback_template = nil, lang = 'en', custom = {})
    return false if response.nil? || fallback_template.nil?
    id = response&.message&.id
    Rails.cache.write('smooch:original:' + id, { project_media_id: pm.id, fallback_template: fallback_template, language: lang, query_date: query_date }.merge(custom).to_json) unless id.blank?
  end

  def self.send_report_from_parent_to_child(parent_id, target_id)
    parent = ProjectMedia.where(id: parent_id).last
    child = ProjectMedia.where(id: target_id).last
    return if parent.nil? || child.nil?
    child.get_annotations('smooch').find_each do |annotation|
      data = JSON.parse(annotation.load.get_field_value('smooch_data'))
      self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
      self.send_report_to_user(data['authorId'], data, parent, data['language'], 'fact_check_report')
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
      text = 'The bot has been de-activated for this conversation. You can now communicate directly to the user in this channel. To reactivate the bot, type `/check bot activate`. <http://help.checkmedia.org/en/articles/3336466-one-on-one-conversation-with-users-on-check-message|Learn about more features of the Slack integration here.>'
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

  def self.refresh_smooch_menu_timeout(message, app_id)
    uid = message['authorId']
    time = Time.now.to_i
    Rails.cache.write("smooch:last_message_from_user:#{uid}", time)
    self.delay_for(15.minutes).timeout_smooch_menu(time, message, app_id)
  end

  def self.timeout_smooch_menu(time, message, app_id)
    uid = message['authorId']
    stored_time = Rails.cache.read("smooch:last_message_from_user:#{uid}").to_i
    return if stored_time > time
    sm = CheckStateMachine.new(uid)
    unless sm.state.value == 'human_mode'
      sm.reset
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(message['authorId'], message['_id'], app_id, 'timeout_requests')
    end
  end
end
