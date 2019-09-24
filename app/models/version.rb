class Version < Partitioned::ByForeignKey
  include PaperTrail::VersionConcern

  attr_accessor :is_being_copied

  before_validation :set_team_id, on: :create
  before_create :set_object_after, :set_user, :set_event_type, :set_project_association, :set_meta, unless: proc { |pt| pt.is_being_copied }
  after_create :increment_project_association_annotations_count
  after_destroy :decrement_project_association_annotations_count

  def self.partition_foreign_key
    :team_id
  end

  def self.partition_normalize_key_value(integer_field_value)
    integer_field_value.to_i / partition_table_size * partition_table_size
  end

  def self.get_team_id_from_item_type(item_type, item)
    case item_type
    when 'Dynamic', 'Task', 'Tag', 'Comment', 'Annotation', 'Flag'
      item.get_team.last
    when 'DynamicAnnotation::Field'
      item.annotation&.get_team&.last
    when 'Relationship'
      item.source&.project&.team_id
    when 'ProjectMedia', 'ProjectSource'
      item.project&.team_id
    when 'Account', 'Source', 'Project', 'Assignment'
      item.team_id
    when 'Team'
      item.id
    else
      nil
    end
  end

  def item_class
    self.item_type.constantize
  end

  def item
    begin
      self.item_class.where(id: self.item_id).last
    rescue
      nil
    end
  end

  def associated
    begin self.associated_type.constantize.where(id: self.associated_id).last rescue nil end
  end

  def project_media
    self.item.project_media if self.item.respond_to?(:project_media)
  end

  def associated_graphql_id
    Base64.encode64("#{self.associated_type}/#{self.associated_id}")
  end

  def source
    self.item.source if self.item.respond_to?(:source)
  end

  def dbid
    self.id
  end

  def annotation
    return Annotation.where(id: self.item.annotation_id).last if self.item.respond_to?(:annotation_id)
    Annotation.where(id: self.item_id).last if self.item_class.new.is_annotation?
  end

  def user
    self.whodunnit.nil? ? nil : User.where(id: self.whodunnit.to_i).last
  end

  def get_object
    self.object.nil? ? {} : JSON.parse(self.object)
  end

  def get_object_changes
    self.object_changes ? JSON.parse(self.object_changes) : {}
  end

  def apply_changes
    object = self.get_object
    changes = self.get_object_changes

    { 'is_annotation?' => 'data', Team => 'settings', DynamicAnnotation::Field => 'value' }.each do |condition, key|
      obj = self.item_class.new
      matches = condition.is_a?(String) ? obj.send(condition) : obj.is_a?(condition)
      if matches
        object[key] = self.deserialize_change(object[key]) if object[key]
        changes[key].collect!{ |change| self.deserialize_change(change) unless change.nil? } if changes[key]
      end
    end

    changes.each do |key, pair|
      object[key] = pair[1]
    end
    object.to_json
  end

  def set_object_after
    self.object_after = self.apply_changes
  end

  def set_user
    self.whodunnit = User.current.id.to_s if self.whodunnit.nil? && User.current.present?
  end

  def set_meta
    item = self.item
    self.meta = item.version_metadata(self.object_changes) if !item.nil? && item.respond_to?(:version_metadata)
  end

  def projects
    ret = []
    if (self.item_type == 'ProjectMedia' && self.event == 'update') || self.event_type == 'copy_projectmedia'
      ret = get_from_object_changes(:project)
    end
    ret
  end

  def teams
    ret = []
    ret = get_from_object_changes(:team) if self.event_type == 'copy_projectmedia'
    ret
  end

  def get_from_object_changes(item)
    ret = []
    item = item.to_s
    changes = self.get_object_changes
    if changes["#{item}_id"]
      ret = changes["#{item}_id"].collect{ |pid| item.classify.constantize.where(id: pid).last }
      ret = [] if ret.include?(nil)
    end
    ret
  end

  def task
    task = nil
    if self.item && self.item_type == 'DynamicAnnotation::Field'
      annotation = self.item.annotation
      if annotation && annotation.annotation_type =~ /response/ && annotation.annotated_type == 'Task'
        task = Task.where(id: annotation.annotated_id).last
      end
    end
    task
  end

  def deserialize_change(d)
    ret = d
    unless d.nil? || !d.is_a?(String)
      ret = YAML.load(d)
    end
    ret
  end

  def object_changes_json
    changes = self.object_changes ? JSON.parse(self.object_changes) : {}
    if changes['data'] && changes['data'].is_a?(Array)
      changes['data'].collect!{ |d| d.is_a?(String) ? self.deserialize_change(d) : d }
    end
    changes.to_json
  end

  def set_event_type
    self.event_type = self.event + '_' + self.item_type.downcase.gsub(/[^a-z]/, '')
  end

  def get_associated
    case self.event_type
    when 'create_comment', 'create_tag', 'create_task', 'create_flag', 'update_task', 'create_dynamic', 'update_dynamic', 'destroy_comment', 'destroy_tag', 'destroy_task', 'destroy_flag', 'create_dynamicannotationfield', 'update_dynamicannotationfield'
      self.get_associated_from_annotation(self.event_type, self.item)
    when 'update_projectmedia', 'update_projectsource', 'copy_projectmedia'
      [self.item.class.name, self.item_id.to_i]
    when 'update_source'
      self.get_associated_from_source
    when 'create_relationship', 'destroy_relationship'
      self.get_associated_from_relationship
    when 'create_assignment', 'destroy_assignment'
      self.get_associated_from_assignment
    end
  end

  def get_associated_from_annotation(event_type, annotation)
    if event_type =~ /dynamicannotationfield/
      self.get_associated_from_dynamic_annotation
    else
      self.get_associated_from_core_annotation(annotation)
    end
  end

  def get_associated_from_core_annotation(annotation)
    associated = [nil, nil]
    if annotation && ['ProjectMedia', 'ProjectSource', 'Task'].include?(annotation.annotated_type)
      associated = annotation.annotation_type =~ /response/ && annotation.annotated_type == 'Task' ? ['ProjectMedia', annotation.annotated.annotated_id.to_i] : [annotation.annotated_type, annotation.annotated_id.to_i]
    end
    associated
  end

  def get_associated_from_dynamic_annotation
    if self.item.is_a?(DynamicAnnotation::Field) && self.item.field_name =~ /^(suggestion|review)_/
      task = begin Task.find(self.item.annotation.annotated_id) rescue nil end
      return ['Task', task.id] unless task.nil?
    end
    annotation = self.item.annotation if self.item
    self.get_associated_from_core_annotation(annotation)
  end

  def get_associated_from_source
    s = self.item
    ps = s.project_sources.last unless s.nil?
    ps.nil? ? [nil, nil] : [ps.class.name, ps.id]
  end

  def get_associated_from_relationship
    r = self.item
    r.nil? ? [nil, nil] : ['ProjectMedia', r.source_id]
  end

  def get_associated_from_assignment
    self.get_associated_from_core_annotation(self.item.assigned) if self.item.assigned_type == 'Annotation'
  end

  def set_project_association
    associated = self.get_associated || [nil, nil]
    self.associated_type = associated[0]
    self.associated_id = associated[1]
  end

  def increment_project_association_annotations_count
    self.change_project_association_annotations_count(1)
  end

  def decrement_project_association_annotations_count
    self.change_project_association_annotations_count(-1)
  end

  def change_project_association_annotations_count(value)
    if !self.associated_type.nil? && !self.associated_id.nil? && self.event_type != 'create_dynamicannotationfield'
      associated = self.associated_type.singularize.camelize.constantize
      pa = associated.find_by(id: self.associated_id)
      if pa
        return unless pa.respond_to?(:cached_annotations_count)
        count = pa.cached_annotations_count + value
        ActiveRecord::Base.connection_pool.with_connection do
          pa.update_columns(cached_annotations_count: count)
        end
      end
    end
  end

  def skip_check_ability
    true
  end

  def get_team_id
    item = self.item
    return nil if item.nil?
    Version.get_team_id_from_item_type(self.item_type, item)
  end

  private

  def set_team_id
    self.team_id = self.get_team_id || Team.current&.id
  end
end
