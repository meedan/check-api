require 'digest'

class Bot::Smooch < BotUser
  class MessageDeliveryError < StandardError; end
  class FinalMessageDeliveryError < MessageDeliveryError; end
  class TurnioMessageDeliveryError < MessageDeliveryError; end
  class SmoochMessageDeliveryError < MessageDeliveryError; end
  class CapiMessageDeliveryError < MessageDeliveryError; end
  class CapiUnhandledMessageWarning < MessageDeliveryError; end

  MESSAGE_BOUNDARY = "\u2063"

  SUPPORTED_INTEGRATION_NAMES = { 'whatsapp' => 'WhatsApp', 'messenger' => 'Facebook Messenger', 'twitter' => 'Twitter', 'telegram' => 'Telegram', 'viber' => 'Viber', 'line' => 'LINE', 'instagram' => 'Instagram' }
  SUPPORTED_INTEGRATIONS = SUPPORTED_INTEGRATION_NAMES.keys
  SUPPORTED_TRIGGER_MAPPING = { 'message:appUser' => :incoming, 'message:delivery:channel' => :outgoing }
  TIPLINE_CUSTOMIZABLE_MESSAGES = ['smooch_message_smooch_bot_greetings', 'submission_prompt', 'add_more_details_state', 'ask_if_ready_state',
                                   'search_state', 'search_no_results', 'search_result_state', 'search_result_is_relevant', 'search_submit',
                                   'newsletter_optin_optout', 'option_not_available', 'timeout', 'smooch_message_smooch_bot_disabled']

  check_settings

  include SmoochMessages
  include SmoochResources
  include SmoochTos
  include SmoochStatus
  include SmoochResend
  include SmoochTeamBotInstallation
  include SmoochNewsletter
  include SmoochSearch
  include SmoochZendesk
  include SmoochTurnio
  include SmoochCapi
  include SmoochStrings
  include SmoochMenus
  include SmoochLanguage
  include SmoochBlocking

  ::ProjectMedia.class_eval do
    attr_accessor :smooch_message

    def report_image
      self.get_dynamic_annotation('report_design')&.report_design_image_url
    end

    def get_deduplicated_tipline_requests
      uids = []
      tipline_requests = []
      pm_ids = ProjectMedia.where(id: self.related_items_ids).map(&:id)
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pm_ids).find_each do |tr|
        uid = tr.tipline_user_uid
        next if uids.include?(uid)
        uids << uid
        tipline_requests << tr
      end
      tipline_requests
    end
  end

  ::Relationship.class_eval do
    def suggestion_accepted?
      self.relationship_type_before_last_save.to_json == Relationship.suggested_type.to_json && self.is_confirmed?
    end

    def self.smooch_send_report(rid)
      relationship = Relationship.find_by_id(rid)
      unless relationship.nil?
        target = relationship.target
        if ::Bot::Smooch.team_has_smooch_bot_installed(target) && relationship.is_confirmed?
          # A relationship created by the Smooch Bot or Alegre Bot is related to search results (unless it's a suggestion that was confirmed), so the user has already received the report as a search result... no need to send another report
          # Only send a report for (1) Confirmed matches created manually OR (2) Suggestions accepted
          created_by_bot = BotUser.where(login: ['alegre', 'smooch'], id: relationship.user_id).exists?
          ::Bot::Smooch.send_report_from_parent_to_child(relationship.source_id, target.id) if !created_by_bot || relationship.confirmed_by
        end
      end
    end

    after_create do
      self.class.delay_for(2.seconds, { queue: 'smooch_priority'}).smooch_send_report(self.id)
    end

    after_update do
      self.class.delay_for(2.seconds, { queue: 'smooch_priority'}).smooch_send_report(self.id) if self.suggestion_accepted?
    end

    after_destroy do
      if self.is_confirmed?
        target = self.target
        unless target.nil?
          s = target.annotations.where(annotation_type: 'verification_status').last&.load
          status = ::Workflow::Workflow.options(target, 'verification_status')[:default]
          if !s.nil? && s.status != status
            s.status = status
            s.save!
          end
        end
      end
    end
  end

  ::Dynamic.class_eval do
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
                text: message[1],
                source: { type: "whatsapp" },
                language: 'en'
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
    ['smooch_app_id', 'turnio_secret', 'capi_whatsapp_business_account_id']
  end

  def self.get_installation(key = nil, value = nil, &block)
    id = nil
    if !key.blank? && !value.blank?
      keys = [key].flatten.map(&:to_s).reject{ |k| k.blank? }
      id = Rails.cache.fetch("smooch_bot_installation_id:#{keys.join(':')}:#{value}", expires_in: 24.hours) do
        self.get_installation_id(keys, value, &block)
      end
    elsif block_given?
      id = self.get_installation_id(key, value, &block)
    end
    smooch_bot_installation = TeamBotInstallation.where(id: id.to_i).last
    settings = smooch_bot_installation&.settings.to_h
    RequestStore.store[:smooch_bot_provider] = 'TURN' unless smooch_bot_installation&.get_turnio_secret&.to_s.blank?
    RequestStore.store[:smooch_bot_provider] = 'CAPI' unless smooch_bot_installation&.get_capi_whatsapp_business_account_id&.to_s.blank?
    RequestStore.store[:smooch_bot_settings] = settings.with_indifferent_access.merge({ team_id: smooch_bot_installation&.team_id.to_i, installation_id: smooch_bot_installation&.id })
    smooch_bot_installation
  end

  def self.get_installation_id(keys = nil, value = nil)
    bot = BotUser.smooch_user
    return nil if bot.nil?
    smooch_bot_installation = nil
    TeamBotInstallation.where(user_id: bot.id).each do |installation|
      key_that_has_value = nil
      installation.settings.each do |k, v|
        key_that_has_value = k.to_s if keys.to_a.include?(k.to_s) && v == value && !value.blank?
      end
      smooch_bot_installation = installation if (block_given? && yield(installation)) || !key_that_has_value.nil?
    end
    smooch_bot_installation&.id
  end

  def self.valid_request?(request)
    self.valid_zendesk_request?(request) || self.valid_turnio_request?(request) || self.valid_capi_request?(request)
  end

  def self.should_ignore_request?(request)
    self.should_ignore_capi_request?(request)
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
      json = self.preprocess_message(body)
      JSON::Validator.validate!(SMOOCH_PAYLOAD_JSON_SCHEMA, json)
      return false if self.user_banned?(json)
      case json['trigger']
      when 'capi:verification'
        'capi:verification'
      when 'message:appUser'
        json['messages'].each do |message|
          SmoochTiplineMessageWorker.perform_async(message, json)
          self.parse_message(message, json['app']['_id'], json)
        end
        true
      when 'message:delivery:failure'
        self.resend_message(json)
        true
      when 'conversation:start', 'conversation:referral'
        message = {
          '_id': json['conversation']['_id'],
          authorId: json['appUser']['_id'],
          type: 'text',
          text: 'start',
          source: { type: json['source']['type'] }
        }.with_indifferent_access
        self.parse_message(message, json['app']['_id'], json)
        true
      when 'message:delivery:channel'
        self.user_received_report(json)
        self.user_received_search_result(json)
        SmoochTiplineMessageWorker.perform_async(json['message'], json)
        true
      else
        false
      end
    rescue StandardError => e
      self.handle_exception(e)
      false
    end
  end

  def self.handle_exception(e)
    raise(e) if Rails.env.development?
    Rails.logger.error("[Smooch Bot] Exception: #{e.message}")
    CheckSentry.notify(e, bot: 'Smooch')
    raise(e) if e.is_a?(AASM::InvalidTransition) # Race condition: return 500 so Smooch can retry it later
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

  def self.start_flow(workflow, language, uid)
    CheckStateMachine.new(uid).start
    if self.should_ask_for_language_confirmation?(uid)
      self.ask_for_language_confirmation(workflow, language, uid)
    else
      self.send_greeting(uid, workflow)
      self.send_message_for_state(uid, workflow, 'main', language)
    end
  end

  def self.parse_query_message(message, app_id, uid, workflow, language)
    sm = CheckStateMachine.new(uid)
    if self.process_menu_option(message, sm.state.value, app_id)
      # Do nothing else - the action will be executed by "process_menu_option" method
    elsif self.is_v2?
      sm.go_to_ask_if_ready unless sm.state.value == 'ask_if_ready'
      self.ask_if_ready_to_submit(uid, workflow, 'ask_if_ready', language)
    else
      self.delay_for(self.time_to_send_request, { queue: 'smooch', retry: false }).bundle_messages(message['authorId'], message['_id'], app_id)
    end
  end

  def self.parse_message_based_on_state(message, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    state = sm.state.value
    language = self.get_user_language(uid, message, state)
    workflow = self.get_workflow(language)
    message['language'] = language

    state = self.send_message_if_disabled_and_return_state(uid, workflow, state)

    if self.clicked_on_template_button?(message)
      self.template_button_click_callback(message, uid, language)
      return true
    end

    case state
    when 'waiting_for_message'
      self.bundle_message(message)
      has_main_menu = (workflow&.dig('smooch_state_main', 'smooch_menu_options').to_a.size > 0)
      if has_main_menu
        self.process_menu_option_or_send_greetings(message, state, app_id, workflow, language, uid)
      else
        self.clear_user_bundled_messages(uid)
        sm.go_to_query
        self.parse_message_based_on_state(message, app_id)
      end
    when 'main', 'secondary', 'subscription', 'search_result'
      unless self.process_menu_option(message, state, app_id)
        self.send_message_for_state(uid, workflow, state, language, self.get_custom_string(:option_not_available, language), 'option_not_available')
      end
    when 'search'
      self.send_message_to_user(uid, self.get_message_for_state(workflow, state, language, uid))
    when 'query', 'ask_if_ready'
      self.parse_query_message(message, app_id, uid, workflow, language)
    when 'add_more_details'
      self.bundle_message(message)
      self.go_to_state_and_ask_if_ready_to_submit(uid, language, workflow)
    when 'resource_waiting_for_user_input'
      resource_id = Rails.cache.read("smooch_resource_waiting_for_user_input:#{uid}")
      resource = TiplineResource.where(team_id: self.config['team_id'].to_i, id: resource_id.to_i).last
      if resource.nil?
        self.send_message_to_user_with_main_menu_appended(uid, 'Sorry, this request has expired. Please start again.', workflow, language)
        self.clear_user_bundled_messages(uid)
      else
        response = resource.handle_user_input(message)
        unless response.blank?
          self.send_message_to_user(uid, response)
          self.send_message_to_user_with_main_menu_appended(uid, 'Use the buttons to navigate.', workflow, language)
        end
        self.bundle_message(message)
        self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'resource_requests', resource)
      end
      sm.reset
      Rails.cache.delete("smooch_resource_waiting_for_user_input:#{uid}")
    end
  end

  def self.process_menu_option_or_send_greetings(message, state, app_id, workflow, language, uid)
    self.process_menu_option(message, state, app_id) || self.start_flow(workflow, language, uid)
  end

  def self.time_to_send_request
    value = self.config['smooch_time_to_send_request'] || 15
    value.to_i.seconds
  end

  def self.get_menu_options(state, workflow, uid)
    if state == 'ask_if_ready'
      [
        { 'smooch_menu_option_keyword' => '1', 'smooch_menu_option_value' => 'search_state' },
        { 'smooch_menu_option_keyword' => '2', 'smooch_menu_option_value' => 'add_more_details_state' },
        { 'smooch_menu_option_keyword' => '3', 'smooch_menu_option_value' => 'main_state' }
      ]
    elsif state == 'search_result'
      [
        { 'smooch_menu_option_keyword' => '1', 'smooch_menu_option_value' => 'search_result_is_relevant' },
        { 'smooch_menu_option_keyword' => '2', 'smooch_menu_option_value' => 'search_result_is_not_relevant' }
      ]
    elsif state == 'subscription' && self.is_v2?
      [
        { 'smooch_menu_option_keyword' => '1', 'smooch_menu_option_value' => 'subscription_confirmation' },
        { 'smooch_menu_option_keyword' => '2', 'smooch_menu_option_value' => 'main_state' }
      ]
    elsif ['query', 'add_more_details'].include?(state) && self.is_v2?
      destination = { 'query' => 'main_state', 'add_more_details' => 'ask_if_ready_state' }[state]
      [{ 'smooch_menu_option_keyword' => '1', 'smooch_menu_option_value' => destination }]
    # Custom menus
    else
      self.get_custom_menu_options(state, workflow, uid)
    end
  end

  def self.get_custom_menu_options(state, workflow, uid)
    options = workflow.dig("smooch_state_#{state}", 'smooch_menu_options').to_a.clone
    if ['main', 'waiting_for_message'].include?(state) && self.is_v2?
      if self.should_ask_for_language_confirmation?(uid)
        options = []
        i = 0
        self.get_supported_languages.each do |l|
          i = self.get_next_menu_item_number(i)
          options << {
            'smooch_menu_option_keyword' => i.to_s,
            'smooch_menu_option_value' => l
          }
        end
      else
        allowed_types = ['query_state', 'subscription_state', 'custom_resource']
        options = options.reject{ |o| !allowed_types.include?(o['smooch_menu_option_value']) }.concat(workflow.dig('smooch_state_secondary', 'smooch_menu_options').to_a.clone.select{ |o| allowed_types.include?(o['smooch_menu_option_value']) })
        language_options = self.get_supported_languages.reject { |l| l == workflow['smooch_workflow_language'] }
        if (language_options.size + options.size) >= 10
          options << {
            'smooch_menu_option_keyword' => 'choose_language',
            'smooch_menu_option_value' => 'choose_language'
          }
        else
          language_options.each do |l|
            options << {
              'smooch_menu_option_keyword' => l,
              'smooch_menu_option_value' => l
            }
          end
        end
        all_options = []
        keyword = 0
        options.reject{ |o| o.blank? }.each do |o|
          keyword = self.get_next_menu_item_number(keyword)
          o2 = o.clone
          o2['smooch_menu_option_keyword'] = keyword.to_s
          all_options << o2
        end
        options = all_options
      end
    end
    options.reject{ |o| o.blank? }
  end

  def self.process_menu_option_value_for_state(value, message, language, workflow, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    self.bundle_message(message)
    new_state = value.gsub(/_state$/, '')
    self.delay_for(self.time_to_send_request, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id) if new_state == 'query' && !self.is_v2?
    sm.send("go_to_#{new_state}")
    self.delay_for(1.seconds, { queue: 'smooch_priority', retry: false }).search(app_id, uid, language, message, self.config['team_id'].to_i, workflow, RequestStore.store[:smooch_bot_provider]) if new_state == 'search'
    self.clear_user_bundled_messages(uid) if new_state == 'main'
    new_state == 'main' && self.is_v2? ? self.send_message_to_user_with_main_menu_appended(uid, self.get_string('cancelled', language), workflow, language) : self.send_message_for_state(uid, workflow, new_state, language)
  end

  def self.process_menu_option_value(value, option, message, language, workflow, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    if value =~ /_state$/
      self.process_menu_option_value_for_state(value, message, language, workflow, app_id)
    elsif value == 'resource'
      pmid = option['smooch_menu_project_media_id'].to_i
      pm = ProjectMedia.where(id: pmid, team_id: self.config['team_id'].to_i).last
      sm.reset
      self.bundle_message(message)
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'menu_options_requests', pm)
      self.send_report_to_user(uid, {}, pm, language)
    elsif value == 'custom_resource'
      sm.reset
      resource = self.send_resource_to_user(uid, workflow, option['smooch_menu_custom_resource_id'].to_s, language)
      self.bundle_message(message)
      reset_state = (resource.content_type != 'dynamic')
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'resource_requests', resource, false, nil, reset_state)
    elsif value == 'subscription_confirmation'
      self.toggle_subscription(uid, language, self.config['team_id'], self.get_platform_from_message(message), workflow)
    elsif value == 'search_result_is_not_relevant'
      self.submit_search_query_for_verification(uid, app_id, workflow, language)
      sm.reset
    elsif value == 'search_result_is_relevant'
      sm.reset
      self.bundle_message(message)
      results = self.get_saved_search_results_for_user(uid)
      self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'relevant_search_result_requests', results, true, self.bundle_search_query(uid))
      self.send_final_message_to_user(uid, self.get_custom_string('search_result_is_relevant', language), workflow, language)
    elsif value =~ CheckCldr::LANGUAGE_FORMAT_REGEXP
      Rails.cache.write("smooch:user_language:#{uid}", value)
      Rails.cache.write("smooch:user_language:#{self.config['team_id']}:#{uid}:confirmed", value)
      sm.send('go_to_main')
      workflow = self.get_workflow(value)
      self.bundle_message(message)
      self.send_greeting(uid, workflow)
      self.send_message_for_state(uid, workflow, 'main', value)
    elsif value == 'choose_language'
      self.reset_user_language(uid)
      self.ask_for_language_confirmation(workflow, language, uid, false)
    end
  end

  def self.is_a_shortcut_for_submission?(state, message)
    self.is_v2? && (state == 'main' || state == 'waiting_for_message') && (
      !message['mediaUrl'].blank? ||
      ::Bot::Alegre.get_number_of_words(message['text'].to_s) > self.min_number_of_words_for_tipline_long_text ||
      !Twitter::TwitterText::Extractor.extract_urls(message['text'].to_s).blank? # URL in message?
      )
  end

  def self.process_menu_option(message, state, app_id)
    uid = message['authorId']
    sm = CheckStateMachine.new(uid)
    language = self.get_user_language(uid, message, state)
    workflow = self.get_workflow(language)
    typed, new_state = self.get_typed_message(message, sm)
    state = new_state if new_state
    if self.should_send_tos?(state, typed)
      sm.reset
      platform = self.get_platform_from_message(message)
      self.send_tos_to_user(workflow, uid, language, platform)
      self.bundle_message(message)
      return true
    end
    workflow ||= {}
    options = self.get_menu_options(state, workflow, uid)
    # Look for button clicks and exact matches to menu options first...
    options.each do |option|
      if option['smooch_menu_option_keyword'].split(',').map(&:downcase).map(&:strip).collect{ |k| k.gsub(/[^a-z0-9]+/, '') }.include?(typed.gsub(/[^a-z0-9]+/, ''))
        self.process_menu_option_value(option['smooch_menu_option_value'], option, message, language, workflow, app_id)
        return true
      end
    end
    # ...if nothing is matched, try using the NLU feature
    if state != 'query'
      options = SmoochNlu.menu_options_from_message(typed, language, options, uid)
      unless options.blank?
        SmoochNlu.process_menu_options(uid, options, message, language, workflow, app_id)
        return true
      end
      resource = TiplineResource.resource_from_message(typed, language, uid)
      unless resource.nil?
        CheckStateMachine.new(uid).reset
        resource = self.send_resource_to_user(uid, workflow, resource.uuid, language)
        self.bundle_message(message)
        self.delay_for(1.seconds, { queue: 'smooch', retry: false }).bundle_messages(uid, message['_id'], app_id, 'resource_requests', resource)
        return true
      end
    end
    # Lastly, check if it's a submission shortcut
    if self.is_a_shortcut_for_submission?(sm.state, message)
      self.bundle_message(message)
      sm.go_to_ask_if_ready
      self.send_message_for_state(uid, workflow, 'ask_if_ready', language)
      return true
    end
    self.bundle_message(message)
    false
  end

  def self.user_received_report(message)
    self.get_installation(self.installation_setting_id_keys, message['app']['_id'])
    original = Rails.cache.read('smooch:original:' + message['message']['_id'])
    unless original.blank?
      original = begin JSON.parse(original) rescue {} end
      if original['fallback_template'] =~ /report/
        pmids = ProjectMedia.find(original['project_media_id']).related_items_ids
        TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pmids, tipline_user_uid: message['appUser']['_id']).find_each do |tr|
          field_name = tr.smooch_report_received_at == 0 ? 'smooch_report_received_at' : 'smooch_report_update_received_at'
          tr.send("#{field_name}=", Time.now.to_i)
          tr.skip_check_ability = true
          tr.save!
        end
      end
    end
  end

  def self.smooch_api_get_messages(app_id, user_id, opts = {})
    self.zendesk_api_get_messages(app_id, user_id, opts)
  end

  def self.api_get_user_data(uid, payload)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.turnio_api_get_user_data(uid, payload)
    elsif RequestStore.store[:smooch_bot_provider] == 'CAPI'
      self.capi_api_get_user_data(uid, payload)
    else
      self.zendesk_api_get_user_data(uid)
    end
  end

  def self.api_get_app_name(app_id)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.turnio_api_get_app_name
    elsif RequestStore.store[:smooch_bot_provider] == 'CAPI'
      self.capi_api_get_app_name
    else
      self.zendesk_api_get_app_data(app_id).app.name
    end
  end

  def self.save_user_information(app_id, uid, payload_json)
    payload = JSON.parse(payload_json)
    self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
    field = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: uid).last
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
      a.annotated_type = 'Team'
      a.annotated_id = self.config['team_id'].to_i
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

  def self.get_user_platform(uid)
    type = begin JSON.parse(DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: uid).last.annotation.load.get_field_value('smooch_user_data')).dig('raw', 'clients', 0, 'platform') rescue nil end
    type ? ::Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[type].to_s : 'Unknown'
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

  def self.send_error_message(message, is_supported)
    m_type = is_supported[:m_type] || 'file'
    max_size = "Uploaded#{m_type.camelize}".constantize.max_size_readable
    error_message = is_supported[:type] == false ? self.get_string(:invalid_format, message['language']) : I18n.t(:smooch_bot_message_size_unsupported, **{ max_size: max_size, locale: message['language'].gsub(/[-_].*$/, '') })
    self.send_message_to_user(message['authorId'], error_message)
  end

  def self.send_message_to_user(uid, text, extra = {}, force = false, preview_url = true, event = nil)
    return if self.config['smooch_disabled'] && !force
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      response = self.turnio_send_message_to_user(uid, text, extra, force, preview_url)
    elsif RequestStore.store[:smooch_bot_provider] == 'CAPI'
      response = self.capi_send_message_to_user(uid, text, extra, force, preview_url)
    else
      response = self.zendesk_send_message_to_user(uid, text, extra, force, preview_url)
    end
    # Store a TiplineMessage
    external_id = self.get_id_from_send_response(response)
    sent_at = DateTime.now
    payload_json = { text: text }.merge(extra).to_json
    team_id = self.config['team_id'].to_i
    platform = RequestStore.store[:smooch_bot_platform] || 'Unknown'
    language = self.get_user_language(uid)
    self.delay.store_sent_tipline_message(uid, external_id, sent_at, payload_json, team_id, platform, language, event)
    response
  end

  def self.store_sent_tipline_message(uid, external_id, sent_at, payload_json, team_id, platform, language, event = nil)
    payload = JSON.parse(payload_json)
    tm = TiplineMessage.new
    tm.uid = uid
    tm.state = 'sent'
    tm.event = event
    tm.direction = :outgoing
    tm.language = language
    tm.platform = platform
    tm.sent_at = sent_at
    tm.external_id = external_id
    tm.payload = payload
    tm.team_id = team_id
    tm.skip_check_ability = true
    tm.save_ignoring_duplicate!
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

  def self.extract_url(text)
    begin
      urls = Twitter::TwitterText::Extractor.extract_urls(text)
      return nil if urls.blank?
      urls_to_ignore = self.config.to_h['smooch_urls_to_ignore'].to_s.split(/\s+/)
      url = urls.reject{ |u| urls_to_ignore.include?(u) }.first
      return nil if url.blank?
      url = 'https://' + url unless url =~ /^https?:\/\//
      url = Addressable::URI.escape(url)
      URI.parse(url)
      m = Link.new url: url
      m.validate_pender_result(false, true)
      if m.pender_error
        raise SecurityError if m.pender_error_code == PenderClient::ErrorCodes::UNSAFE
        nil
      else
        m
      end
    rescue URI::InvalidURIError => e
      CheckSentry.notify(e, bot: 'Smooch', extra: { method: 'extract_url' })
      nil
    end
  end

  def self.extract_claim(text)
    claim = ''
    text.split(MESSAGE_BOUNDARY).each do |part|
      claim = part.chomp.strip if part.size > claim.size
    end
    claim
  end

  def self.add_hashtags(text, pm)
    hashtags = Twitter::TwitterText::Extractor.extract_hashtags(text)
    return nil if hashtags.blank?
    # Only add team tags.
    TagText.where("team_id = ? AND text IN (?)", pm.team_id, hashtags).each do |tag|
      unless pm.annotations('tag').map(&:tag_text).include?(tag.text)
        Tag.create!(tag: tag.id, annotator: pm.user, annotated: pm)
      end
    end
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
      link = self.extract_url(text)
      pm = nil
      extra = {}
      if link.nil?
        # strip and remove null bytes
        claim = self.extract_claim(text).gsub(/\s+/, ' ').strip.gsub("\u0000", "\\u0000")
        extra = { quote: claim }
        pm = ProjectMedia.joins(:media).where('trim(lower(quote)) = ?', claim.downcase).where('project_medias.team_id' => team.id).last
        # Don't create a new text media if it's an unconfirmed request with just a few words
        if pm.nil? && message['archived'] == CheckArchivedFlags::FlagCodes::UNCONFIRMED && ::Bot::Alegre.get_number_of_words(claim) < self.min_number_of_words_for_tipline_long_text
          return team
        end
      else
        extra = { url: link.url }
        # Normalized url before query DB
        url_from_pender = Link.normalized(link.url, team.get_pender_key)
        pm = ProjectMedia.joins(:media).where('medias.url' => url_from_pender, 'project_medias.team_id' => team.id).last
      end
      if pm.nil?
        type = link.nil? ? 'Claim' : 'Link'
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
    extra.merge!({ archived: message['archived'] }) unless message['archived'].blank?
    channel_value = self.get_smooch_channel(message)
    extra.merge!({ channel: {main: channel_value }}) unless channel_value.nil?
    pm = ProjectMedia.create!({ media_type: type, smooch_message: message }.merge(extra))
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

  def self.store_media(media_id, mime_type)
    if RequestStore.store[:smooch_bot_provider] == 'TURN'
      self.store_turnio_media(media_id, mime_type)
    elsif RequestStore.store[:smooch_bot_provider] == 'CAPI'
      self.store_capi_media(media_id, mime_type)
    end
  end

  def self.convert_media_information(message)
    if ['audio', 'video', 'image', 'file', 'voice'].include?(message['type'])
      mime_type = message.dig(message['type'], 'mime_type').to_s.gsub(/;.*$/, '')
      {
        mediaUrl: self.store_media(message.dig(message['type'], 'id'), mime_type),
        mediaType: mime_type
      }
    else
      {}
    end
  end

  def self.save_media_message(message)
    message = self.adjust_media_type(message)
    allowed_types = { 'image' => 'jpeg', 'video' => 'mp4', 'audio' => 'mp3' }
    return unless allowed_types.keys.include?(message['type'])

    URI(message['mediaUrl']).open do |f|
      text = message['text']

      data = f.read
      hash = Digest::MD5.hexdigest(data)
      filename = "#{hash}.#{allowed_types[message['type']]}"
      filepath = File.join(Rails.root, 'tmp', filename)
      media_type = "Uploaded#{message['type'].camelize}"
      File.atomic_write(filepath) { |file| file.write(data) }
      team_id = self.config['team_id'].to_i
      pm = ProjectMedia.joins(:media).where('medias.type' => media_type, 'medias.file' => filename, 'project_medias.team_id' => team_id).last
      if pm.nil?
        pm = ProjectMedia.new(archived: message['archived'], media_type: media_type, smooch_message: message)
        pm.is_being_created = true
        # set channel
        channel_value = self.get_smooch_channel(message)
        pm.channel = { main: channel_value } unless channel_value.nil?
        File.open(filepath) do |f2|
          pm.file = f2
          pm.save!
        end
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
    parent.get_deduplicated_tipline_requests.each do |tipline_request|
      data = tipline_request.smooch_data
      self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
      self.send_correction_to_user(data, parent, tipline_request, last_published_at, action, report.get_field_value('published_count').to_i) unless self.config['smooch_disabled']
    end
  end

  def self.send_correction_to_user(data, pm, tipline_request, last_published_at, action, published_count = 0)
    subscribed_at = tipline_request.created_at
    self.get_platform_from_message(data)
    uid = data['authorId']
    lang = data['language']
    # User received a report before
    if subscribed_at.to_i < last_published_at.to_i && published_count > 0
      if ['publish', 'republish_and_resend'].include?(action)
        self.send_report_to_user(uid, data, pm, lang, 'fact_check_report_updated', self.get_string(:report_updated, lang), tipline_request)
      end
    # First report
    else
      self.send_report_to_user(uid, data, pm, lang, 'fact_check_report', nil, tipline_request)
    end
  end

  def self.send_report_to_user(uid, data, pm, lang = 'en', fallback_template = nil, pre_message = nil, tipline_request = nil)
    parent = Relationship.confirmed_parent(pm)
    return if parent.nil?
    report = parent.get_dynamic_annotation('report_design')
    Rails.logger.info "[Smooch Bot] Trying to send report to user #{uid} for item with ID #{pm.id}..."

    # Only send a report if these conditions are met
    should_send_report_in_language = report.should_send_report_in_this_language?(lang)
    if report&.get_field_value('state') == 'published' && [CheckArchivedFlags::FlagCodes::NONE, CheckArchivedFlags::FlagCodes::UNCONFIRMED].include?(parent.archived) && should_send_report_in_language

      # Map the template name to a ticker field
      ticker_field_name = {
        fact_check_report_updated: 'smooch_report_correction_sent_at',
        fact_check_report: 'smooch_report_sent_at'
      }[fallback_template.to_s.to_sym]

      unless pre_message.blank?
        self.send_message_to_user(uid, pre_message)
        sleep 1
      end
      last_smooch_response = nil
      if report.report_design_field_value('use_introduction')
        introduction = report.report_design_introduction(data, lang)
        smooch_intro_response = self.send_message_to_user(uid, introduction)
        Rails.logger.info "[Smooch Bot] Sent report introduction to user #{uid} for item with ID #{pm.id}, response was: #{smooch_intro_response&.body}"
        sleep 1
      end
      if report.report_design_field_value('use_text_message')
        workflow = self.get_workflow(lang)
        last_smooch_response = self.send_final_messages_to_user(uid, report.report_design_text(lang), workflow, lang, 1, true, 'report')
        Rails.logger.info "[Smooch Bot] Sent text report to user #{uid} for item with ID #{pm.id}, response was: #{last_smooch_response&.body}"
      elsif report.report_design_field_value('use_visual_card')
        last_smooch_response = self.send_message_to_user(uid, '', { 'type' => 'image', 'mediaUrl' => report.report_design_image_url }, false, true, 'report')
        Rails.logger.info "[Smooch Bot] Sent report visual card to user #{uid} for item with ID #{pm.id}, response was: #{last_smooch_response&.body}"
      end
      self.save_smooch_response(last_smooch_response, parent, data['received'], fallback_template, lang)

      if tipline_request.present? && ticker_field_name.present? && last_smooch_response.present?
        tipline_request.update_column(ticker_field_name, Time.now.to_i)
      end
    else
      Rails.logger.info "[Smooch Bot] Not sending report to user #{uid} for item with ID #{pm.id}. Report state: #{report&.get_field_value('state')} | Item archived flag: #{parent.archived} | Should send report in #{lang}? #{should_send_report_in_language}"
    end
  end

  def self.safely_parse_response_body(response)
    begin JSON.parse(response.body) rescue nil end
  end

  def self.get_id_from_send_response(response)
    response_body = self.safely_parse_response_body(response)
    (RequestStore.store[:smooch_bot_provider] == 'TURN' || RequestStore.store[:smooch_bot_provider] == 'CAPI') ? response_body&.dig('messages', 0, 'id') : response&.body&.message&.id
  end

  def self.save_smooch_response(response, pm, query_date, fallback_template = nil, lang = 'en', custom = {}, expire = nil)
    return false if response.nil? || fallback_template.nil?
    id = self.get_id_from_send_response(response)
    unless id.blank?
      key = 'smooch:original:' + id
      value = { project_media_id: pm&.id, fallback_template: fallback_template, language: lang, query_date: (query_date || Time.now.to_i) }.merge(custom).to_json
      Rails.cache.write(key, value, expires_in: expire)
    end
  end

  def self.send_report_from_parent_to_child(parent_id, target_id)
    parent = ProjectMedia.where(id: parent_id).last
    child = ProjectMedia.where(id: target_id).last
    return if parent.nil? || child.nil?
    child.tipline_requests.find_each do |tr|
      data = tr.smooch_data
      self.get_platform_from_message(data)
      self.get_installation(self.installation_setting_id_keys, data['app_id']) if self.config.blank?
      self.send_report_to_user(tr.tipline_user_uid, data, parent, tr.language, 'fact_check_report')
    end
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
      Bot::Slack.delay_for(1.second, { queue: 'smooch' }).send_message_to_slack_conversation(text, slack_data['token'], slack_data['channel'])
    end
    self.delay_for(15.minutes, { queue: 'smooch' }).timeout_smooch_slack_human_conversation(uid, time)
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
    time = Time.now.to_f
    Rails.cache.write("smooch:last_message_from_user:#{uid}", time)
    self.delay_for(15.minutes, { queue: 'smooch' }).timeout_smooch_menu(time, message, app_id, RequestStore.store[:smooch_bot_provider])
  end

  def self.timeout_smooch_menu(time, message, app_id, provider)
    self.get_installation(self.installation_setting_id_keys, app_id) if self.config.blank?
    RequestStore.store[:smooch_bot_provider] = provider
    return if self.config['smooch_disable_timeout']
    uid = message['authorId']
    language = self.get_user_language(uid)
    stored_time = Rails.cache.read("smooch:last_message_from_user:#{uid}").to_i
    return if stored_time > time
    sm = CheckStateMachine.new(uid)
    unless ['human_mode', 'waiting_for_message'].include?(sm.state.value)
      uid = message['authorId']
      annotated = nil
      type = 'timeout_requests'
      if sm.state.value == 'search_result'
        annotated = self.get_saved_search_results_for_user(uid)
        type = 'timeout_search_requests'
      end
      self.send_message_to_user_on_timeout(uid, language)
      self.bundle_messages(uid, message['_id'], app_id, type, annotated, true)
      sm.reset
    end
  end

  def self.sanitize_installation(team_bot_installation, blast_secret_settings = false)
    team_bot_installation.apply_default_settings
    team_bot_installation.reset_smooch_authorization_token
    if blast_secret_settings
      [
       'capi_whatsapp_business_account_id', 'capi_verify_token', 'capi_permanent_token', 'capi_phone_number_id', 'capi_phone_number', # CAPI
       'smooch_app_id', 'smooch_secret_key_key_id', 'smooch_secret_key_secret', 'smooch_webhook_secret', # Smooch
       'turnio_secret', 'turnio_token', 'turnio_host' # On-prem
      ].each do |key|
        team_bot_installation.settings.delete(key)
      end
    end
    team_bot_installation
  end

  def self.default_settings
    settings = [
      {
        'smooch_workflow_language' => 'en',
        'smooch_state_main' => {
          'smooch_menu_message' => '',
          'smooch_menu_options' => []
        },
        'smooch_state_secondary' => {
          'smooch_menu_message' => '',
          'smooch_menu_options' => []
        },
        'smooch_state_query' => {
          'smooch_menu_message' => '',
          'smooch_menu_options' => []
        },
      }
    ]
    ::Bot::Smooch::TIPLINE_CUSTOMIZABLE_MESSAGES.each do |key|
      settings[0][key] = ''
    end
    settings
  end
end
