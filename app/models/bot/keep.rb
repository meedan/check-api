class Bot::Keep

  def self.archiver_annotation_types
    [
      'keep_backup', # VideoVault
      'pender_archive', # Screenshot
      'archive_is' # Archive.is
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
    after_create :create_all_archive_annotations

    def should_skip_create_archive_annotation?(type)
      !DynamicAnnotation::AnnotationType.where(annotation_type: type).exists? || !self.media.is_a?(Link) || self.project.team.get_limits_keep_integration == false || self.project.team.send("get_archive_#{type}_enabled").to_i != 1
    end

    def create_archive_annotation(type)
      return if self.should_skip_create_archive_annotation?(type)

      a = Dynamic.new
      a.skip_check_ability = true
      a.skip_notifications = true
      a.disable_es_callbacks = Rails.env.to_s == 'test'
      a.annotation_type = type
      a.annotated = self

      data = nil
      begin
        data = JSON.parse(self.media.pender_embed.data['embed'])
      rescue
        data = self.media.pender_data
      end

      archives = data.has_key?('archives') ? data['archives'] : {}
      response = Bot::Keep.set_response_based_on_pender_data(type, archives[Bot::Keep.annotation_type_to_archiver(type)])
      a.set_fields = { "#{type}_response" => response.to_json }.to_json
      a.save!
    end

    private

    def create_all_archive_annotations
      Bot::Keep.archiver_annotation_types.each do |type|
        self.create_archive_annotation(type)
      end
    end
  end

  Team.class_eval do
    Bot::Keep.archiver_annotation_types.each do |type|
      define_method :"archive_#{type}_enabled=" do |enabled|
        self.send("set_archive_#{type}_enabled", enabled)
      end
    end
  end
end
