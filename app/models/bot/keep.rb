class Bot::Keep
  def self.run(body)
    json = JSON.parse(body)
    pm = ProjectMedia.where(id: json['data']['dbid']).last
    user = User.where(id: json['user_id']).last
    if pm.present? && user.present?
      User.current = user
      pm.create_all_archive_annotations
      User.current = nil
    end
  end

  def self.valid_request?(request)
    request.base_url == CONFIG['checkdesk_base_url_private']
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
      bot = TeamBot.where(identifier: 'keep').last
      installation = TeamBotInstallation.where(team_id: team.id, team_bot_id: bot.id).last
      getter = "get_archive_#{type}_enabled"
      !DynamicAnnotation::AnnotationType.where(annotation_type: type).exists? || !self.media.is_a?(Link) || team.get_limits_keep.to_i == 0 || installation.nil? || !installation.send(getter)
    end

    def create_archive_annotation(type)
      return if self.should_skip_create_archive_annotation?(type)

      data = nil
      begin
        data = JSON.parse(self.media.pender_embed.data['embed'])
      rescue
        data = self.media.pender_data
      end

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
