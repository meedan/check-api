require 'digest'

class Bot::Smooch
  ::Workflow::VerificationStatus.class_eval do
    check_workflow from: :any, to: :any, actions: :replicate_status_to_children
    check_workflow from: :any, to: :terminal, actions: :reply_to_smooch_users
  end

  ::Dynamic.class_eval do
    after_save :send_meme_to_smooch_users, if: proc { |d| d.annotation_type == 'memebuster' }

    private

    def send_meme_to_smooch_users
      ::Bot::Smooch.delay_for(1.second, { queue: 'smooch', retry: 0 }).send_meme_to_smooch_users(self.id) if self.action == 'publish'
    end
  end

  ::DynamicAnnotation::Field.class_eval do
    protected

    def replicate_status_to_children
      pm = self.annotation.annotated
      bot = TeamBot.where(identifier: 'smooch').last
      return if TeamBotInstallation.where(team_id: pm.project.team_id, team_bot_id: bot.id).last.nil?
      ::Bot::Smooch.delay_for(1.second, { queue: 'smooch', retry: 0 }).replicate_status_to_children(self.annotation.annotated_id, self.value, User.current&.id, Team.current&.id)
    end

    def reply_to_smooch_users
      ::Bot::Smooch.delay_for(1.second, { queue: 'smooch', retry: 0 }).reply_to_smooch_users(self.annotation.annotated_id, self.value)
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
              type: 'string'
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

  def self.get_installation(key, value)
    bot = TeamBot.where(identifier: 'smooch').last
    return nil if bot.nil?
    smooch_bot_installation = nil
    TeamBotInstallation.where(team_bot_id: bot.id).each do |installation|
      smooch_bot_installation = installation if installation.settings.with_indifferent_access[key] == value
    end
    settings = smooch_bot_installation&.settings || {}
    RequestStore.store[:smooch_bot_settings] = settings.with_indifferent_access.merge({ team_id: smooch_bot_installation&.team_id.to_i })
    smooch_bot_installation
  end

  def self.valid_request?(request)
    key = request.headers['X-API-Key'].to_s
    installation = self.get_installation('smooch_webhook_secret', key)
    !key.blank? && !installation.nil?
  end

  def self.config
    RequestStore.store[:smooch_bot_settings]
  end

  def self.webhook(request)
    Bot::Smooch.run(request.body.read)
  end

  def self.run(body)
    begin
      json = JSON.parse(body)
      JSON::Validator.validate!(SMOOCH_PAYLOAD_JSON_SCHEMA, json)
      case json['trigger']
      when 'message:appUser'
        json['messages'].each do |message|
          self.process_message(message, json['app']['_id'])
        end
        true
      when 'message:delivery:failure'
        self.resend_message(json)
        true
      else
        false
      end
    rescue StandardError => e
      Rails.logger.info "Exception when calling Smooch Bot for this message: #{e.message}"
      Airbrake.notify(e) if Airbrake.configuration.api_key
      false
    end
  end

  def self.resend_message(message)
    code = begin message['error']['underlyingError']['errors'][0]['code'] rescue 0 end
    if code == 470
      self.delay_for(1.second, { queue: 'smooch', retry: 0 }).resend_message_after_window(message.to_json)
    end
  end

  def self.resend_message_after_window(message)
    message = JSON.parse(message)
    self.get_installation('smooch_app_id', message['app']['_id'])
    pmid = Rails.cache.read('smooch:smooch_message_id:project_media_id:' + message['message']['_id']).to_i
    pm = ProjectMedia.where(id: pmid).last
    unless pm.nil?
      lang = Bot::Alegre.default.language_object(pm, :value)
      status = I18n.t('statuses.media.' + pm.last_status.gsub(/^false$/, 'not_true') + '.label', locale: lang)
      fallback = I18n.t(:smooch_bot_result, locale: lang, status: status, url: pm.embed_url)
      ::Bot::Smooch.send_message_to_user(message['appUser']['_id'], "&[#{fallback}](#{self.config['smooch_template_namespace']}, check_verification_results, #{status}, #{pm.embed_url})")
    end
  end

  def self.get_language(message)
    text = message['text'].to_s
    lang = text.blank? ? nil : Bot::Alegre.default.get_language_from_alegre_for_text(text)
    lang = 'en' if lang.blank? || !I18n.available_locales.include?(lang.to_sym)
    lang
  end

  def self.process_message(message, app_id)
    return if message['authorId'] == self.config['smooch_bot_id']
    self.refresh_window(message['authorId'], app_id)
    lang = message['language'] = self.get_language(message)
    sm = CheckStateMachine.new(message['authorId'])

    if sm.state.value == 'waiting_for_message'
      sm.send_message
      sm.message = message.to_json
      self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_ask_for_confirmation, locale: lang))

    elsif sm.state.value == 'waiting_for_confirmation'
      sm.confirm
      saved_message = JSON.parse(sm.message.value)
      lang = saved_message['language']
      if message['text'].to_i == 1
        unless self.user_already_sent_message(saved_message)
          self.save_message_later(saved_message, app_id)
          self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_message_confirmed, locale: lang))
        end
      else
        self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_message_unconfirmed, locale: lang))
      end
    end
  end

  def self.refresh_window(uid, app_id)
    return if self.config['smooch_window_duration'].to_i == 0
    key = 'smooch:' + uid + ':reminder_job_id'
    job_id = Rails.cache.read(key)
    Sidekiq::Status.cancel(job_id) unless job_id.nil?
    job_id = SmoochPingWorker.perform_in(self.config['smooch_window_duration'].to_i.hours, uid, app_id)
    Rails.cache.write(key, job_id)
  end

  def self.get_text_from_message(message)
    text = message['text'][/[^\s]+\.[^\s]+/, 0].to_s.gsub(/^https?:\/\//, '')
    text = message['text'] if text.blank?
    text.downcase
  end

  def self.user_already_sent_message(message)
    hash = nil
    case message['type']
    when 'text'
      text = self.get_text_from_message(message)
      hash = Digest::MD5.hexdigest(text)
    when 'image'
      open(message['mediaUrl']) do |f|
        hash = Digest::MD5.hexdigest(f.read)
      end
    when 'file'
      if message['mediaType'].to_s =~ /^image\//
        open(message['mediaUrl']) do |f|
          hash = Digest::MD5.hexdigest(f.read)
        end
      else
        self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_message_type_unsupported, locale: message['language']))
        return true
      end
    else
      self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_message_type_unsupported, locale: message['language']))
      return true
    end

    key = 'smooch:' + message['authorId'] + ':' + hash
    if Rails.cache.read(key)
      self.send_message_to_user(message['authorId'], I18n.t(:smooch_bot_message_sent, locale: message['language']))
      true
    else
      Rails.cache.write(key, Time.now.to_i)
      false
    end
  end

  def self.send_message_to_user(uid, text, extra = {})
    payload = { scope: 'app' }
    jwtHeader = { kid: self.config['smooch_secret_key_key_id'] }
    token = JWT.encode payload, self.config['smooch_secret_key_secret'], 'HS256', jwtHeader
    config = SmoochApi::Configuration.new
    config.api_key['Authorization'] = token
    config.api_key_prefix['Authorization'] = 'Bearer'
    api_client = SmoochApi::ApiClient.new(config)

    api_instance = SmoochApi::ConversationApi.new(api_client)
    app_id = self.config['smooch_app_id']
    params = { 'role' => 'appMaker', 'type' => 'text', 'text' => text }.merge(extra)
    message_post_body = SmoochApi::MessagePost.new(params)
    begin
      api_instance.post_message(app_id, uid, message_post_body)
    rescue SmoochApi::ApiError => e
      Rails.logger.info "Exception when sending message to Smooch: #{e.response_body}"
      Airbrake.notify(e) if Airbrake.configuration.api_key
    end
  end

  def self.save_message_later(message, app_id)
    type = (message['type'] == 'text' && !message['text'][/https?:\/\/[^\s]+/, 0].blank?) ? 'link' : message['type']
    SmoochWorker.perform_in(1.second, message.to_json, type, app_id)
  end

  def self.save_message(message, app_id)
    json = JSON.parse(message)
    self.get_installation('smooch_app_id', app_id)
    json['project_id'] = self.get_project_id(json)

    pm = case json['type']
         when 'text'
           self.save_text_message(json)
         when 'image'
           self.save_image_message(json)
         when 'file'
           json['mediaType'].to_s =~ /^image\// ? self.save_image_message(json) : return
         else
           return
         end

    a = Dynamic.new
    a.skip_check_ability = true
    a.skip_notifications = true
    a.disable_es_callbacks = Rails.env.to_s == 'test'
    a.annotation_type = 'smooch'
    a.annotated = pm
    a.set_fields = {  smooch_data: json.merge({ app_id: app_id }).to_json }.to_json
    a.save!

    if pm.is_finished?
      self.send_verification_results_to_user(json['authorId'], pm, pm.last_status, json['language'])
      self.send_meme_to_user(json['authorId'], pm, json['language'])
    end
  end

  def self.get_project_id(_json)
    project_id = self.config['smooch_project_id'].to_i
    raise "Project ID #{project_id} does not belong to team #{self.config['team_id']}" if Project.where(id: project_id, team_id: self.config['team_id'].to_i).last.nil?
    project_id
  end

  def self.get_url_from_text(text)
    begin
      url = text[/[^\s]+\.[^\s]+/, 0].to_s
      return nil if url.blank?
      url = 'https://' + url unless url =~ /^https?:\/\//
      URI.parse(url)
      m = Link.new url: url
      m.validate_pender_result(false, true)
      m.pender_error ? nil : m.url
    rescue URI::InvalidURIError
      nil
    end
  end

  def self.save_text_message(json)
    text = json['text']
    url = self.get_url_from_text(text)

    if url.nil?
      pm = ProjectMedia.joins(:media).where('lower(quote) = ?', text.downcase).where('project_medias.project_id' => json['project_id']).last ||
           ProjectMedia.create!(project_id: json['project_id'], quote: text)
    else
      pm = ProjectMedia.joins(:media).where('medias.url' => url, 'project_medias.project_id' => json['project_id']).last
      if pm.nil?
        pm = ProjectMedia.create!(project_id: json['project_id'], url: url)
        pm.embed = { description: text }.to_json if text != url
      elsif text != url
        Comment.create! annotated: pm, text: text, force_version: true
      end
    end
    pm
  end

  def self.save_image_message(json)
    open(json['mediaUrl']) do |f|
      data = f.read
      hash = Digest::MD5.hexdigest(data)
      filepath = File.join(Rails.root, 'tmp', "#{hash}.jpeg")
      File.atomic_write(filepath) { |file| file.write(data) }
      pm = ProjectMedia.joins(:media).where('medias.type' => 'UploadedImage', 'medias.file' => "#{hash}.jpeg", 'project_medias.project_id' => json['project_id']).last
      if pm.nil?
        m = UploadedImage.new
        File.open(filepath) do |f2|
          m.file = f2
        end
        m.save!
        pm = ProjectMedia.create!(project_id: json['project_id'], media: m)
        pm.embed = { description: json['text'] }.to_json unless json['text'].blank?
      elsif !json['text'].blank?
        Comment.create! annotated: pm, text: json['text'], force_version: true
      end
      FileUtils.rm_f filepath
      pm
    end
  end

  def self.reply_to_smooch_users(pmid, status)
    pm = ProjectMedia.where(id: pmid).last
    unless pm.nil?
      pm.get_annotations('smooch').find_each do |annotation|
        data = JSON.parse(annotation.load.get_field_value('smooch_data'))
        self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
        self.send_verification_results_to_user(data['authorId'], pm, status, data['language'])
      end
    end
  end

  def self.replicate_status_to_children(pmid, status, uid, tid)
    pm = ProjectMedia.where(id: pmid).last
    return if pm.nil?
    User.current = User.where(id: uid).last
    Team.current = Team.where(id: tid).last
    pm.targets.each do |target|
      s = target.annotations.where(annotation_type: 'verification_status').last.load
      next if s.nil? || s.status == status
      s.status = status
      s.save!
    end
    User.current = nil
    Team.current = nil
  end

  def self.send_verification_results_to_user(uid, pm, status, lang)
    key = 'smooch:' + uid + ':reminder_job_id'
    job_id = Rails.cache.read(key)
    unless job_id.nil?
      Sidekiq::Status.cancel(job_id)
      Rails.cache.delete(key)
    end

    extra = {
      metadata: {
        id: pm.id
      }
    }
    status = I18n.t('statuses.media.' + status.gsub(/^false$/, 'not_true') + '.label', locale: lang)
    response = ::Bot::Smooch.send_message_to_user(uid, I18n.t(:smooch_bot_result, locale: lang, status: status, url: pm.embed_url), extra)
    id = response&.message&.id
    Rails.cache.write('smooch:smooch_message_id:project_media_id:' + id, pm.id) unless id.blank?
    response
  end

  def self.send_meme_to_user(uid, pm, lang)
    annotation = pm.get_annotations('memebuster').last&.load
    return if annotation.nil? || annotation.get_field_value('memebuster_published_at').blank?
    meme = annotation.memebuster_png_path(false)
    Bot::Smooch.send_message_to_user(uid, I18n.t(:smooch_bot_meme, locale: lang, url: pm.embed_url), { type: 'image', mediaUrl: meme })
  end

  def self.send_meme_to_smooch_users(annotation_id)
    annotation = Dynamic.where(id: annotation_id).last
    pm = annotation&.annotated
    return if pm.nil?
    meme = annotation.memebuster_png_path(true)
    pms = [pm] + pm.targets.to_a
    pms.each do |pm2|
      pm2.get_annotations('smooch').find_each do |a|
        data = JSON.parse(a.load.get_field_value('smooch_data'))
        self.get_installation('smooch_app_id', data['app_id']) if self.config.blank?
        ::Bot::Smooch.send_message_to_user(data['authorId'], I18n.t(:smooch_bot_meme, locale: data['language'], url: pm.embed_url), { type: 'image', mediaUrl: meme })
      end
    end
    annotation.set_fields = { memebuster_published_at: Time.now }.to_json
    annotation.save!
  end
end
