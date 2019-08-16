class Bot::Keep < BotUser

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
      'archive_is',     # Archive.is
      'archive_org'     # Archive.org
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
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'].to_s, payload)
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

  def self.webhook(request)
    payload = JSON.parse(request.raw_post)
    if payload['url']
      link = Link.where(url: payload['url']).last
      type = Bot::Keep.archiver_to_annotation_type(payload['type'])
      unless link.nil?
        response = Bot::Keep.set_response_based_on_pender_data(type, payload) || { error: true }
        m = link.metadata_annotation
        data = JSON.parse(m.get_field_value('metadata_value'))
        data['archives'] ||= {}
        data['archives'][payload['type']] = response
        response.each { |key, value| data[key] = value }
        m.set_fields = { metadata_value: data.to_json }.to_json
        m.save!

        ProjectMedia.where(media_id: link.id).each do |pm|
          annotation = pm.annotations.where(annotation_type: type).last

          unless annotation.nil?
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

  ProjectMedia.class_eval do
    def should_skip_create_archive_annotation?(type)
      team = self.project.team
      bot = BotUser.where(login: 'keep').last
      installation = TeamBotInstallation.where(team_id: team.id, user_id: bot&.id.to_i).last
      getter = "get_archive_#{type}_enabled"
      !DynamicAnnotation::AnnotationType.where(annotation_type: type).exists? || !self.media.is_a?(Link) || installation.nil? || !installation.send(getter)
    end

    def create_archive_annotation(type)
      return if self.should_skip_create_archive_annotation?(type)

      data = begin JSON.parse(self.media.metadata_annotation.get_field_value('metadata_value')) rescue self.media.pender_data end

      return unless data.has_key?('archives')

      a = Dynamic.new
      a.skip_check_ability = true
      a.skip_notifications = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.annotation_type = type
      a.annotated = self

      archives = data['archives']
      response = Bot::Keep.set_response_based_on_pender_data(type, archives[Bot::Keep.annotation_type_to_archiver(type)])
      a.set_fields = { "#{type}_response" => response.to_json }.to_json
      a.save!
    end

    def reset_archive_response(annotation)
      return if self.should_skip_create_archive_annotation?(annotation.annotation_type)
      a = annotation.load || annotation
      a.skip_check_ability = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.set_fields = { "#{a.annotation_type}_response" => {}.to_json }.to_json
      a.save!
    end

    def create_all_archive_annotations
      Bot::Keep.archiver_annotation_types.each do |type|
        self.create_archive_annotation(type)
      end
    end
  end
end
