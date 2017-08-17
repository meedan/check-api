class DynamicAnnotation::Field < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value

  before_validation :set_annotation_type, :set_field_type

  validate :field_format

  def to_s
    [
      "field_formatter_#{self.annotation.annotation_type}_#{self.field_name}",
      "field_formatter_name_#{self.field_name}",
      "field_formatter_type_#{self.field_instance.field_type}",
    ].each do |name|
      if self.respond_to?(name)
        return self.send(name)
      end
    end
    self.value
  end

  def as_json(options = {})
    json = super(options)
    json.merge({ formatted_value: self.to_s })
  end

  include Versioned

  private

  def field_format
    [
      "field_validator_#{self.annotation.annotation_type}_#{self.field_name}",
      "field_validator_name_#{self.field_name}",
      "field_validator_type_#{self.field_instance.field_type}",
    ].each do |name|
      self.send(name) if self.respond_to?(name)
    end
  end

  def set_annotation_type
    self.annotation_type ||= self.annotation.annotation_type
  end

  def set_field_type
    self.field_type ||= self.field_instance.field_type
  end
end
