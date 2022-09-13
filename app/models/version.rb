class Version < Partitioned::ByForeignKey
  include PaperTrail::VersionConcern
  include CheckPermissions
  include ActiveRecordExtensions

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
    obj = self.item
    if obj.class.name != 'ProjectMedia'
      obj = self.item.respond_to?(:project_media) ? self.item.project_media : nil
    end
    obj
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
    if self.meta.blank?
      item = self.item
      self.meta = item.version_metadata(self.object_changes) if !item.nil? && item.respond_to?(:version_metadata)
    end
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
    changes = begin JSON.parse(self.object_changes) rescue {} end
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
    when 'create_tag', 'create_dynamic', 'update_dynamic', 'destroy_tag', 'create_dynamicannotationfield', 'update_dynamicannotationfield'
      self.get_associated_from_annotation(self.event_type, self.item)
    when 'create_projectmedia', 'update_projectmedia'
      [self.item.class.name, self.item_id.to_i]
    when 'create_relationship', 'update_relationship', 'destroy_relationship'
      self.get_associated_from_relationship
    when 'create_assignment', 'destroy_assignment'
      self.get_associated_from_assignment
    when 'create_claimdescription', 'update_claimdescription'
      ['ProjectMedia', self.item.project_media_id]
    when 'create_factcheck'
      ['ProjectMedia', self.item.claim_description.project_media_id]
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
    if annotation && ['ProjectMedia', 'Task'].include?(annotation.annotated_type)
      associated = annotation.annotation_type =~ /response/ && annotation.annotated_type == 'Task' ? ['ProjectMedia', annotation.annotated.annotated_id.to_i] : [annotation.annotated_type, annotation.annotated_id.to_i]
    end
    associated
  end

  def get_associated_from_dynamic_annotation
    annotation = self.item.annotation if self.item
    self.get_associated_from_core_annotation(annotation)
  end

  def get_associated_from_relationship
    r = self.item
    r.nil? ? [nil, nil] : ['ProjectMedia', r.target_id]
  end

  def get_associated_from_assignment
    item = self.item
    self.get_associated_from_core_annotation(item.assigned) if !item.nil? && item.assigned_type == 'Annotation'
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
      return if associated == NilClass
      pa = associated.find_by(id: self.associated_id)
      if pa
        return unless pa.respond_to?(:cached_annotations_count)
        count = pa.cached_annotations_count + value
        ApplicationRecord.connection_pool.with_connection do
          pa.update_columns(cached_annotations_count: count)
        end
      end
    end
  end

  def skip_check_ability
    true
  end

  def get_team_id
    self.item.nil? ? nil : self.item.team&.id
  end

  private

  def set_team_id
    self.team_id = self.get_team_id || Team.current&.id
  end
end
