require 'active_support/concern'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  def get_team_for_auto_tasks
    self.team || self.project&.team
  end

  def create_auto_tasks(tasks = [])
    team = self.get_team_for_auto_tasks
    return if team.nil? || team.is_being_copied
    self.set_tasks_responses ||= {}
    if tasks.blank?
      tasks = self.project.nil? ? Project.new(team: team).auto_tasks : self.project.auto_tasks
    end
    created = []
    tasks.each do |task|
      t = Task.new
      t.label = task.label
      t.type = task.task_type
      t.description = task.description
      t.team_task_id = task.id
      t.json_schema = task.json_schema
      t.options = task.options unless task.options.blank?
      t.annotator = User.current
      t.annotated = self
      t.skip_check_ability = true
      t.skip_notifications = true
      t.save!
      created << t
      # set auto-response
      self.set_jsonld_response(task) unless task.mapping.blank?
    end
    self.respond_to_auto_tasks(created)
  end

  private

  def set_project_source
    team = self.team || self.project&.team
    return if team.nil? || team.is_being_copied
    self.create_project_source
  end

  def create_annotation
    unless self.set_annotation.blank?
      params = JSON.parse(self.set_annotation)
      annotation = Dynamic.new
      annotation.annotated = self
      annotation.annotation_type = params['annotation_type']
      annotation.set_fields = params['set_fields']
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.skip_notifications = true
      annotation.save!
    end
  end

  def set_quote_metadata
    self.metadata = ({ title: self.media.quote }.to_json) unless self.media.quote.blank?
    set_title_for_files unless self.media.file.blank?
  end

  def set_title_for_files
    if self.user&.login == 'smooch' && ['UploadedVideo', 'UploadedImage'].include?(self.media.type)
      type_count = Media.where(type: self.media.type).joins("INNER JOIN project_medias pm ON medias.id = pm.media_id")
      .where("pm.team_id = ?", self.team&.id).count
      type = self.media.type == 'UploadedVideo' ? 'video' : 'image'
      title = "#{type}-#{self.team&.slug}-#{type_count}"
    else
      file_path = self.media.file.path
      title = File.basename(file_path, File.extname(file_path))
    end
    self.metadata = ({ title: title }.to_json)
  end

  protected

  def create_video_or_image(media_type = 'UploadedImage')
    m = media_type.constantize.new
    m.file = self.file
    m.save!
    m
  end

  def create_claim
    m = Claim.new
    m.quote = self.quote
    m.quote_attributions = self.quote_attributions
    m.save!
    m
  end

  def create_link
    url = Link.normalized(self.url)
    Link.find_or_create_by(url: url)
  end

  def create_media
    m = nil
    self.set_media_type if self.media_type.blank?
    case self.media_type
    when 'UploadedImage', 'UploadedVideo'
      m = self.create_video_or_image(media_type)
    when 'Claim'
      m = self.create_claim
    when 'Link'
      m = self.create_link
    end
    m
  end

  def set_media_type
    if !self.url.blank?
      self.media_type = 'Link'
    elsif !self.quote.blank?
      self.media_type = 'Claim'
    end
  end

  def set_jsonld_response(task)
    jsonld = self.metadata['raw']['json+ld'] if self.metadata.has_key?('raw')
    unless jsonld.nil?
      value = self.get_response_value(jsonld, task)
      self.set_tasks_responses[Task.slug(task['label'])] = value unless value.blank?
    end
  end

  def get_response_value(jsonld, task)
    require 'jsonpath'
    mapping = task['mapping']
    self.mapping_suggestions(task, mapping['type']).each do |name|
      return self.send(name, jsonld, mapping) if self.respond_to?(name)
    end
    data = mapping_value(jsonld, mapping)
    (!data.blank? && data.kind_of?(String)) ? mapping['prefix'].gsub(/\s+$/, '') + ' ' + data : ''
  end

  def mapping_value(jsonld, mapping)
    begin
      value = JsonPath.new(mapping['match']).first(jsonld)
    rescue
      value = nil
    end
    value
  end

  def mapping_suggestions(task, mapping_type)
    [
      "mapping_#{Task.slug(task['label'])}",
      "mapping_#{task['type']}_#{mapping_type}",
      "mapping_#{task['type']}",
    ]
  end

  def respond_to_auto_tasks(tasks)
    # set_tasks_responses = { task_slug (string) => response (string) }
    responses = self.set_tasks_responses.to_h
    tasks.each do |task|
      if responses.has_key?(task.slug)
        task = Task.find(task.id)
        type = "task_response_#{task.type}"
        fields = {
          "response_#{task.type}" => responses[task.slug]
        }
        task.response = { annotation_type: type, set_fields: fields.to_json }.to_json
        task.save!
      end
    end
  end

  def create_project_source
    return if self.project_id.blank?
    a = self.media.account
    source = Account.create_for_source(a.url, nil, false, self.disable_es_callbacks).source unless a.nil?
    if source.nil?
      cs = ClaimSource.where(media_id: self.media_id).last
      source = cs.source unless cs.nil?
    end
    unless source.nil?
      unless ProjectSource.where(project_id: self.project_id, source_id: source.id).exists?
        ps = ProjectSource.new
        ps.project_id = self.project_id
        ps.source_id = source.id
        ps.disable_es_callbacks = self.disable_es_callbacks
        ps.skip_check_ability = true
        ps.save!
      end
    end
  end

  def create_relationship(type = Relationship.default_type)
    unless self.related_to_id.nil?
      related = ProjectMedia.where(id: self.related_to_id).last
      unless related.nil?
        r = Relationship.new
        r.skip_check_ability = true
        r.relationship_type = type
        r.source_id = related.id
        r.target_id = self.id
        r.save!
      else
        raise 'Could not create related item'
      end
    end
  end

  def copy_to_project
    ProjectMedia.create!(project_id: self.copy_to_project_id, media_id: self.media_id, user: User.current, skip_notifications: self.skip_notifications, skip_rules: true) if self.copy_to_project_id
  end

  def add_to_project
    ProjectMediaProject.create!(project_id: self.add_to_project_id, project_media_id: self.id, skip_notifications: self.skip_notifications) if self.add_to_project_id && ProjectMediaProject.where(project_id: self.add_to_project_id, project_media_id: self.id).last.nil?
  end

  def remove_from_project
    if self.remove_from_project_id
      pmp = ProjectMediaProject.where(project_id: self.remove_from_project_id, project_media_id: self.id).last
      pmp.destroy! unless pmp.nil?
    end
  end
end
