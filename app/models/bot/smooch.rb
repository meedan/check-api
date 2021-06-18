require 'digest'

class SmoochBotDeliveryFailure < StandardError
end

class Bot::Smooch < BotUser

  MESSAGE_BOUNDARY = "\u2063"

  SUPPORTED_INTEGRATIONS = %w(whatsapp messenger twitter telegram viber line)

  check_settings

  include SmoochMessages
  include SmoochResources
  include SmoochTos
  include SmoochStatus
  include SmoochResend
  include SmoochTeamBotInstallation
  include SmoochZendesk
  include SmoochTurnio

  ::ProjectMedia.class_eval do
    attr_accessor :smooch_message

    def report_image
      self.get_dynamic_annotation('report_design')&.report_design_image_url(nil)
    end
  end

  ::Relationship.class_eval do
    def is_valid_smooch_relationship?
      self.is_confirmed?
    end

    def suggestion_accepted?
      self.relationship_type_was.to_json == Relationship.suggested_type.to_json && self.is_confirmed?
    end

    def inherit_status_and_send_report
      target = self.target
      parent = self.source
      if ::Bot::Smooch.team_has_smooch_bot_installed(target) && self.is_valid_smooch_relationship?
        s = target.annotations.where(annotation_type: 'verification_status').last&.load
        status = parent.last_verification_status
        if !s.nil? && s.status != status
          s.status = status
          s.save!
        end
        ::Bot::Smooch.delay_for(3.seconds).send_report_from_parent_to_child(parent.id, target.id)
      end
    end

    after_create do
      self.inherit_status_and_send_report
    end

    after_update do
      self.inherit_status_and_send_report if self.suggestion_accepted?
    end

    after_destroy do
      if self.is_valid_smooch_relationship?
        target = self.target
        s = target.annotations.where(annotation_type: 'verification_status').last&.load
        status = ::Workflow::Workflow.options(target, 'verification_status')[:default]
        if !s.nil? && s.status != status
          s.status = status
          s.save!
        end
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
              Bot::Smooch.get_installation(Bot::Smooch.installation_setting_id_keys, app_id)
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
        sm = CheckStateMachine.new(uid)
        sm.leave_human_mode if sm.state.value == 'human_mode'
      end
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
          field = DynamicAnnotation::Field.where('field_name = ? AND dynamic_annotation_fields_value(field_name, value) = ?', 'smooch_user_id', data['authorId'].to_json).last
          return '' if field.nil?
          user = JSON.parse(field.annotation.load.get_field_value('smooch_user_data')).with_indifferent_access[:raw][:clients][0]
          case user[:platform]
          when 'whatsapp'
            user[:displayName]
          when 'telegram'
            '@' + user[:raw][:username].to_s
          when 'messenger', 'viber', 'line'
            user[:externalId]
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

    def smooch_user_request_language
      Concurrent::Future.execute(executor: POOL) do
        object_after = JSON.parse(self.object_after)
        return '' unless object_after['field_name'] == 'smooch_data'
        JSON.parse(object_after['value'])['language'].to_s
      end
    end

    private

    def get_slack_channel_url(obj, data)
      slack_channel_url = nil
      # Fetch project from Smooch Bot and fallback to obj.project_id
      pid = nil
      bot = BotUser.smooch_user
      tbi = TeamBotInstallation.where(team_id: obj.team_id, user_id: bot&.id.to_i).last
      pid =  tbi.get_smooch_project_id unless tbi.nil?
      pid ||= obj.project_id
      smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', annotation_type: 'smooch_user')
      .where('dynamic_annotation_fields_value(field_name, value) = ?', data['authorId'].to_json)
      .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
      .where("a.annotated_type = ? AND a.annotated_id = ?", 'Project', pid).last
      unless smooch_user_data.nil?
        field_value = DynamicAnnotation::Field.where(field_name: 'smooch_user_slack_channel_url', annotation_type: 'smooch_user', annotation_id: smooch_user_data.annotation_id).last
        slack_channel_url = field_value.value unless field_value.nil?
      end
      slack_channel_url
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
    bot = BotUser.smooch_user
    tbi = TeamBotInstallation.where(team_id: pm.team_id, user_id: bot&.id.to_i).last
    !tbi.nil? && tbi.settings.with_indifferent_access[:smooch_disabled].blank?
  end

  def self.installation_setting_id_keys
    ['smooch_app_id', 'turnio_secret']
  end

  def self.get_installation(key = nil, value = nil)
    bot = BotUser.smooch_user
    return nil if bot.nil?
    smooch_bot_installation = nil
    keys = [key].flatten.map(&:to_s).reject{ |k| k.blank? }
    TeamBotInstallation.where(user_id: bot.id).each do |installation|
      has_key_and_value = false
      installation.settings.each do |k, v|
        has_key_and_value = true if keys.include?(k.to_s) && v == value
      end
      smooch_bot_installation = installation if (block_given? && yield(installation)) || has_key_and_value
    end
    settings = smooch_bot_installation&.settings || {}
    RequestStore.store[:smooch_bot_settings] = settings.with_indifferent_access.merge({ team_id: smooch_bot_installation&.team_id.to_i })
    smooch_bot_installation
  end

  def self.valid_request?(request)
    self.valid_zendesk_request?(request) || self.valid_turnio_request?(request)
  end

  def self.config
    RequestStore.store[:smooch_bot_settings]
  end

  def self.webhook(request)
    # FIXME This should be packaged as an event "invoke_webhook" + data payload
    Bot::Smooch.run(request.body.read)
  end

  def self.preprocess_message(body)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.preprocess_turnio_message(body)
    else
      JSON.parse(body)
    end
  end

  def self.run(body)
    begin
      json = self.preprocess_message(body)
      JSON::Validator.validate!(SMOOCH_PAYLOAD_JSON_SCHEMA, json)
      case json['trigger']
      when 'message:appUser'
        json['messages'].each do |message|
          self.parse_message(message, json['app']['_id'], json)
        end
        true
      when 'message:delivery:failure'
        self.resend_message(json)
        true
      when 'message:delivery:channel'
        self.user_received_report(json)
        true
      else
        false
      end
    rescue StandardError => e
      raise(e) if Rails.env.development?
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

    state = self.send_message_if_disabled_and_return_state(uid, workflow, state)

    case state
    when 'waiting_for_message'
      self.bundle_message(message)
      has_main_menu = (workflow&.dig('smooch_state_main', 'smooch_menu_options').to_a.size > 0)
      if has_main_menu
        sm.start
        main_message = [workflow['smooch_message_smooch_bot_greetings'], self.get_message_for_state(workflow, 'main', language)].join("\n\n")
        self.send_message_to_user(uid, utmize_urls(main_message, 'resource'))
      else
        self.clear_user_bundled_messages(uid)
        sm.go_to_query
        self.parse_message_based_on_state(message, app_id)
      end
    when 'main', 'secondary'
      if !self.process_menu_option(message, state, app_id)
        no_option_message = [workflow['smooch_message_smooch_bot_option_not_available'], self.get_message_for_state(workflow, state, language)].join("\n\n")
        self.send_message_to_user(uid, utmize_urls(no_option_message, 'resource'))
      end
    when 'query'
      (self.process_menu_option(message, state, app_id) && self.clear_user_bundled_messages(uid)) ||
        self.delay_for(15.seconds, { queue: 'smooch_ping', retry: false }).bundle_messages(message['authorId'], message['_id'], app_id)
    end
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
          self.send_message_to_user(uid, utmize_urls(self.get_message_for_state(workflow, new_state, language), 'resource'))
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
        elsif option['smooch_menu_option_value'] =~ /^[a-z]{2}(_[A-Z]{2})?$/
          Rails.cache.write("smooch:user_language:#{uid}", option['smooch_menu_option_value'])
          sm.send('go_to_main')
          workflow = self.get_workflow(option['smooch_menu_option_value'])
          self.bundle_message(message)
          self.send_message_to_user(uid, utmize_urls(self.get_message_for_state(workflow, 'main', option['smooch_menu_option_value']), 'resource'))
        end
        return true
      end
    end
    self.bundle_message(message)
    return false
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
    self.get_installation(self.installation_setting_id_keys, message['app']['_id'])
    original = Rails.cache.read('smooch:original:' + message['message']['_id'])
    unless original.blank?
      original = JSON.parse(original)
      if original['fallback_template'] =~ /report/
        pmids = ProjectMedia.find(original['project_media_id']).related_items_ids
        DynamicAnnotation::Field.joins(:annotation).where(field_name: 'smooch_data', 'annotations.annotated_type' => 'ProjectMedia', 'annotations.annotated_id' => pmids).where("value_json ->> 'authorId' = ?", message['appUser']['_id']).each do |f|
          a = f.annotation.load
          a.set_fields = { smooch_report_received: Time.now.to_i }.to_json
          a.save!
        end
      end
    end
  end

  def self.smooch_api_get_messages(app_id, user_id, opts = {})
    self.zendesk_api_get_messages(app_id, user_id, opts)
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

  def self.api_get_user_data(uid, payload)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.turnio_api_get_user_data(uid, payload)
    else
      self.zendesk_api_get_user_data(uid) 
    end
  end

  def self.api_get_app_name(app_id)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.turnio_api_get_app_name
    else
      self.zendesk_api_get_app_data(uid).app.name
    end
  end

  def self.save_user_information(app_id, uid, payload_json)
    payload = JSON.parse(payload_json)
    self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
    # FIXME Shouldn't we make sure this is an annotation in the right project?
    field = DynamicAnnotation::Field.where('field_name = ? AND dynamic_annotation_fields_value(field_name, value) = ?', 'smooch_user_id', uid.to_json).last
    if field.nil?
      user = self.api_get_user_data(uid, payload)
      app_name = self.api_get_app_name(app_id)

      identifier = self.get_identifier(user, uid)

      data = {
        id: uid,
        raw: user,
        identifier: identifier,
        app_name: app_name
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
      query = { field_name: 'smooch_user_data', json: { app_name: app_name, identifier: identifier } }.to_json
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

  def self.get_identifier(user, uid)
    # This identifier is used on the Slack side in order to connect a Slack conversation to a Smooch user
    identifier = case user.dig(:clients, 0, :platform)
                 when 'whatsapp'
                   user.dig(:clients, 0, :displayName)
                 when 'messenger'
                   user.dig(:clients, 0, :info, :avatarUrl)&.match(/psid=([0-9]+)/)&.to_a&.at(1)
                 when 'twitter'
                   user.dig(:clients, 0, :info, :avatarUrl)&.match(/profile_images\/([0-9]+)\//)&.to_a&.at(1)
                 when 'telegram'
                   # The message on Slack side doesn't contain a unique Telegram identifier
                   nil
                 when 'viber'
                   viber_match = user.dig(:clients, 0, 'raw', 'avatar')&.match(/dlid=([^&]+)/)
                   viber_match.nil? ? nil : viber_match[1][0..26]
                 when 'line'
                   user.dig(:clients, 0, 'raw', 'pictureUrl')&.match(/sprofile\.line-scdn\.net\/(.*)/)&.to_a&.at(1)
                 end
      identifier ||= uid
      Digest::MD5.hexdigest(identifier)
  end

  def self.save_message_later_and_reply_to_user(message, app_id)
    self.save_message_later(message, app_id)
    workflow = self.get_workflow(message['language'])
    self.send_message_to_user(message['authorId'], utmize_urls(workflow['smooch_message_smooch_bot_message_confirmed'], 'resource'))
  end

  def self.get_text_from_message(message)
    text = message['text'][/[^\s]+\.[^\s]+/, 0].to_s.gsub(/^https?:\/\//, '')
    text = message['text'] if text.blank?
    text.downcase
  end

  def self.send_error_message(message, is_supported)
    m_type = is_supported[:m_type] || 'file'
    max_size = "Uploaded#{m_type.camelize}".constantize.max_size_readable
    workflow = self.get_workflow(message['language'])
    error_message = is_supported[:type] == false ? workflow['smooch_message_smooch_bot_message_type_unsupported'] : I18n.t(:smooch_bot_message_size_unsupported, { max_size: max_size, locale: message['language'] })
    self.send_message_to_user(message['authorId'], error_message)
  end
    
  def self.send_message_to_user(uid, text, extra = {}, force = false)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.turnio_send_message_to_user(uid, text, extra, force)
    else
      self.zendesk_send_message_to_user(uid, text, extra, force)
    end
  end

  def self.create_project_media_from_message(message)
    pm =
      if message['type'] == 'text'
        self.save_text_message(message)
      else
        self.save_media_message(message)
      end
    # Update archived column
    if pm.is_a?(ProjectMedia) && pm.archived == CheckArchivedFlags::FlagCodes::UNCONFIRMED && message['archived'] != CheckArchivedFlags::FlagCodes::UNCONFIRMED
      pm = ProjectMedia.find(pm.id)
      pm.skip_check_ability = true
      pm.archived = CheckArchivedFlags::FlagCodes::NONE
      pm.save!
    end
    pm
  end

  def self.get_project_id(_message = nil)
    project_id = self.config['smooch_project_id'].to_i
    raise "Project ID #{project_id} does not belong to team #{self.config['team_id']}" if Project.where(id: project_id, team_id: self.config['team_id'].to_i).last.nil?
    project_id
  end

  def self.extract_url(text)
    begin
      urls = Twitter::TwitterText::Extractor.extract_urls(text)
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
    hashtags = Twitter::TwitterText::Extractor.extract_hashtags(text)
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

  # Don't save as a ProjectMedia if it contains only menu options
  def self.is_a_valid_text_message?(text)
    !text.split(/#{MESSAGE_BOUNDARY}|\s+/).reject{ |m| m =~ /^[0-9]*$/ }.empty?
  end

  def self.save_text_message(message)
    text = message['text']
    team = Team.where(id: config['team_id'].to_i).last

    return team unless self.is_a_valid_text_message?(text)

    begin
      url = self.extract_url(text)
      pm = nil
      extra = {}
      if url.nil?
        claim = self.extract_claim(text)
        extra = { quote: claim }
        pm = ProjectMedia.joins(:media).where('lower(quote) = ?', claim.downcase).where('project_medias.team_id' => team.id).last
      else
        extra = { url: url }
        pm = ProjectMedia.joins(:media).where('medias.url' => url, 'project_medias.team_id' => team.id).last
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
    pm = ProjectMedia.create!({ project_id: message['project_id'], media_type: type, smooch_message: message }.merge(extra))
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
      message['type'] = m[1] unless m.nil?
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
      pm = ProjectMedia.joins(:media).where('medias.type' => media_type, 'medias.file' => filename, 'project_medias.project_id' => message['project_id']).last
      if pm.nil?
        m = media_type.constantize.new
        File.open(filepath) do |f2|
          m.file = f2
        end
        m.save!
        pm = ProjectMedia.create!(project_id: message['project_id'], archived: message['archived'], media: m, media_type: media_type, smooch_message: message)
        pm.is_being_created = true
      end
      FileUtils.rm_f filepath

      self.add_hashtags(text, pm)

      pm
    end
  end

  def self.send_report_to_users(pm, action)
    parent = Relationship.confirmed_parent(pm)
    report = parent.get_annotations('report_design').last&.load
    return if report.nil?
    last_published_at = report.get_field_value('last_published').to_i
    ProjectMedia.where(id: parent.related_items_ids).each do |pm2|
      pm2.get_annotations('smooch').find_each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
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
    parent = Relationship.confirmed_parent(pm)
    report = parent.get_dynamic_annotation('report_design')
    Rails.logger.info "[Smooch Bot] Sending report to user #{uid} for item with ID #{pm.id}..."
    if report&.get_field_value('state') == 'published' && parent.archived == CheckArchivedFlags::FlagCodes::NONE
      last_smooch_response = nil
      if report.report_design_field_value('use_introduction', lang)
        introduction = report.report_design_introduction(data, lang)
        last_smooch_response = self.send_message_to_user(uid, introduction)
        Rails.logger.info "[Smooch Bot] Sent report introduction to user #{uid} for item with ID #{pm.id}, response was: #{last_smooch_response.to_json}"
        sleep 1
      end
      if report.report_design_field_value('use_visual_card', lang)
        last_smooch_response = self.send_message_to_user(uid, '', { 'type' => 'image', 'mediaUrl' => report.report_design_image_url(lang) })
        Rails.logger.info "[Smooch Bot] Sent report visual card to user #{uid} for item with ID #{pm.id}, response was: #{last_smooch_response.to_json}"
        sleep 3
      end
      if report.report_design_field_value('use_text_message', lang)
        last_smooch_response = self.send_message_to_user(uid, report.report_design_text(lang))
        Rails.logger.info "[Smooch Bot] Sent text report to user #{uid} for item with ID #{pm.id}, response was: #{last_smooch_response.to_json}"
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
      self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
      self.send_report_to_user(data['authorId'], data, parent, data['language'], 'fact_check_report')
    end
  end

  def self.replicate_status_to_children(pm_id, status, uid, tid)
    pm = ProjectMedia.where(id: pm_id).last
    return if pm.nil?
    User.current = User.where(id: uid).last
    Team.current = Team.where(id: tid).last
    pm.source_relationships.confirmed.joins('INNER JOIN users ON users.id = relationships.user_id').where("users.type != 'BotUser' OR users.type IS NULL").find_each do |relationship|
      target = relationship.target
      s = target.annotations.where(annotation_type: 'verification_status').last&.load
      next if s.nil? || s.status == status
      s.status = status
      s.save!
    end
    User.current = nil
    Team.current = nil
  end

  def self.send_message_on_status_change(pm_id, status, request_actor_session_id = nil)
    RequestStore[:actor_session_id] = request_actor_session_id unless request_actor_session_id.nil?
    pm = ProjectMedia.find_by_id(pm_id)
    return if pm.nil?
    requestors_count = 0
    parent = Relationship.where(target_id: pm.id).last&.source || pm
    ProjectMedia.where(id: parent.related_items_ids).each do |pm2|
      pm2.get_annotations('smooch').find_each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
        message = parent.team.get_status_message_for_language(status, data['language'])
        unless message.blank?
          response = self.send_message_to_user(data['authorId'], message)
          self.save_smooch_response(response, parent, data['received'].to_i, 'fact_check_status', data['language'], { message: message })
          requestors_count += 1
        end
      end
    end
    CheckNotification::InfoMessages.send('sent_message_to_requestors_on_status_change', status: pm.status_i18n, requestors_count: requestors_count) if requestors_count > 0
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
    self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
    language = self.get_user_language(message)
    workflow = self.get_workflow(language)
    uid = message['authorId']
    stored_time = Rails.cache.read("smooch:last_message_from_user:#{uid}").to_i
    return if stored_time > time
    sm = CheckStateMachine.new(uid)
    unless sm.state.value == 'human_mode'
      sm.reset
      self.send_resource_to_user_on_timeout(uid, workflow)
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(message['authorId'], message['_id'], app_id, 'timeout_requests')
    end
  end

  def self.sanitize_installation(team_bot_installation, blast_secret_settings = false)
    team_bot_installation.apply_default_settings
    team_bot_installation.reset_smooch_authorization_token
    if blast_secret_settings
      team_bot_installation.settings.delete('smooch_app_id')
      team_bot_installation.settings.delete('smooch_secret_key_key_id')
      team_bot_installation.settings.delete('smooch_secret_key_secret')
      team_bot_installation.settings.delete('smooch_webhook_secret')
      team_bot_installation.settings.delete('turnio_secret')
      team_bot_installation.settings.delete('turnio_token')
    end
    team_bot_installation
  end
end
