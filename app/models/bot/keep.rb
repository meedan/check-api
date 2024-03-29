class Bot::Keep < BotUser
  class ObjectNotReadyError < StandardError
    def initialize(object_type = 'object')
      @object_type = object_type
      super
    end

    def message
      "#{@object_type} not found. If link was submitted recently, try again later."
    end
  end

  check_settings

  def self.run(body)
    pm = ProjectMedia.where(id: body.dig(:data, :dbid)).last
    user = User.where(id: body.dig(:user_id)).last
    if pm.present? && user.present?
      User.current = user
      pm.create_all_archive_annotations
      User.current = nil
    end
  end

  def self.archiver_annotation_types
    [
      'keep_backup',    # VideoVault
      'pender_archive', # Screenshot
      'archive_org',    # Archive.org
      'perma_cc'       # Perma.cc
    ]
  end

  def self.archiver_to_annotation_type(archiver)
    {
      'screenshot' => 'pender_archive',
      'video_vault' => 'keep_backup'
    }[archiver] || archiver
  end

  def self.annotation_type_to_archiver(type)
    {
      'pender_archive' => 'screenshot',
      'keep_backup' => 'video_vault'
    }[type] || type
  end

  def self.valid_request?(request)
    begin
      payload = request.raw_post
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CheckConfig.get('secret_token').to_s, payload)
      if Rack::Utils.secure_compare(signature, request.headers['X-Signature'].to_s)
        JSON.parse(request.raw_post)
        return true
      else
        return false
      end
    rescue
      return false
    end
  end

  def self.save_archive_information(link, response, payload)
    m = link.metadata_annotation
    data = begin JSON.parse(m.get_field_value('metadata_value')) rescue {} end
    data['archives'] ||= {}
    data['archives'][payload['type']] = response
    m.set_fields = { metadata_value: data.to_json }.to_json
    m.save!
  end

  def self.webhook(request)
    payload = JSON.parse(request.raw_post)
    if payload['url']
      link = Link.where(url: payload['url']).last
      raise ObjectNotReadyError.new('Link') unless link

      if payload['type'] == 'metrics'
        Bot::Keep.update_metrics(link, payload['metrics'])
      else
        type = Bot::Keep.archiver_to_annotation_type(payload['type'])
        response = Bot::Keep.set_response_based_on_pender_data(type, payload) || { error: true }
        Bot::Keep.save_archive_information(link, response, payload)

        project_media = ProjectMedia.where(media_id: link.id)
        raise ObjectNotReadyError.new('ProjectMedia') unless project_media.count > 0

        project_media.find_each do |pm|
          annotation = pm.annotations.where(annotation_type: 'archiver').last
          raise ObjectNotReadyError.new('Archiver annotation for ProjectMedia') if annotation.nil?

          unless !DynamicAnnotation::Field.where(field_name: "#{type}_response", annotation_id: annotation.id).exists?
            annotation = annotation.load
            annotation.skip_check_ability = true
            annotation.disable_es_callbacks = Rails.env.to_s == 'test'
            annotation.set_fields = { "#{type}_response" => response.to_json }.to_json
            annotation.save!
          end
        end
      end
    end
  end

  def self.set_response_based_on_pender_data(type, data)
    method = "set_#{type}_response_based_on_pender_data"
    Bot::Keep.respond_to?(method) ? Bot::Keep.send(method, data) : (data || {})
  end

  def self.set_pender_archive_response_based_on_pender_data(data)
    (!data.nil? && data['screenshot_taken'].to_i == 1) ? { screenshot_taken: 1, screenshot_url: data['screenshot'] || data['screenshot_url'] } : {}
  end

  def self.update_metrics(link, metrics)
    ProjectMedia.where(media_id: link.id).find_each do |pm|
      a = Dynamic.where(annotation_type: 'metrics', annotated_type: 'ProjectMedia', annotated_id: pm.id).last
      if a.nil?
        a = Dynamic.new
        a.skip_check_ability = true
        a.skip_notifications = true
        a.disable_es_callbacks = Rails.env.to_s == 'test'
        a.annotation_type = 'metrics'
        a.annotated = pm
      end
      current = begin JSON.parse(a.get_field_value('metrics_data')) rescue {} end
      a.set_fields = { metrics_data: current.merge(metrics).to_json }.to_json
      a.skip_trashed_validation = true
      a.save!
    end
  end

  ProjectMedia.class_eval do
    def should_skip_create_archive_annotation?(type)
      team = self.team
      bot = BotUser.keep_user
      installation = TeamBotInstallation.where(team_id: team.id, user_id: bot&.id.to_i).last
      getter = "get_archive_#{type}_enabled"
      !DynamicAnnotation::AnnotationType.where(annotation_type: 'archiver').exists? || !DynamicAnnotation::FieldInstance.where(name: "#{type}_response").exists? || !self.media.is_a?(Link) || installation.nil? || !installation.send(getter)
    end

    def create_archive_annotation(type)
      return if self.should_skip_create_archive_annotation?(type)
      data = begin JSON.parse(self.media.metadata_annotation.get_field_value('metadata_value')) rescue self.media.pender_data end

      return unless data&.has_key?('archives')
      a = Dynamic.where(annotation_type: 'archiver', annotated_type: self.class_name, annotated_id: self.id).last
      if a.nil?
        a = Dynamic.new
        a.skip_notifications = true
        a.disable_es_callbacks = Rails.env.to_s == 'test'
        a.annotation_type = 'archiver'
        a.annotated = self
      end

      archives = data['archives']
      response = Bot::Keep.set_response_based_on_pender_data(type, archives[Bot::Keep.annotation_type_to_archiver(type)])
      a.set_fields = { "#{type}_response" => response.to_json }.to_json
      a.skip_check_ability = true
      a.save!
    end

    def reset_archive_response(annotation, archiver)
      return if self.should_skip_create_archive_annotation?(archiver)
      a = annotation.load || annotation
      a.skip_check_ability = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.set_fields = { "#{archiver}_response" => {}.to_json }.to_json
      a.save!
    end

    def create_all_archive_annotations
      Bot::Keep.archiver_annotation_types.each do |type|
        self.create_archive_annotation(type)
      end
    end
  end

  Team.class_eval do
    def enabled_archivers
      bot = BotUser.find_by(login: 'keep')
      bot_installation = self.team_bot_installations.find_by(user_id: bot&.id)
      return '' if bot_installation.nil?
      archivers = []
      bot_installation.settings.each do |setting, value|
        if value
          match = setting.match(/archive_(.*)_enabled/)
          archivers << match[1] unless match.nil?
        end
      end
      archivers.join(',')
    end
  end
end
