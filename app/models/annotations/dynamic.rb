class Dynamic < ActiveRecord::Base
  include AnnotationBase

  attr_accessor :set_fields

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id'
  
  after_save :add_update_elasticsearch_dynamic_annotation
  after_create :create_fields

  validate :annotation_type_exists
  validate :mandatory_fields_are_set

  def data
    fields = self.fields
    {
      'fields' => fields,
      'indexable' => fields.map(&:value).select{ |v| v.is_a?(String) }.join('. ')
    }
  end

  private

  def add_update_elasticsearch_dynamic_annotation
    add_update_media_search_child('dynamic_search', ['indexable']) if self.fields.count > 0
  end

  def annotation_type_exists
    errors.add(:annotation_type, 'does not exist') if self.annotation_type != 'dynamic' && DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last.nil?
  end

  def create_fields
    unless self.set_fields.blank?
      data = JSON.parse(self.set_fields)
      data.each do |field_name, value|
        f = DynamicAnnotation::Field.new
        f.field_name = field_name
        f.value = value
        f.annotation_id = self.id
        f.save!
      end
    end
  end

  def mandatory_fields_are_set
    if !self.set_fields.blank? && self.annotation_type != 'dynamic'
      annotation_type = DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last
      fields_set = JSON.parse(self.set_fields).keys
      mandatory_fields = annotation_type.schema.reject{ |instance| instance.optional }.map(&:name)
      errors.add(:base, 'Please set all mandatory fields') unless (mandatory_fields - fields_set).empty?
    end
  end
end
