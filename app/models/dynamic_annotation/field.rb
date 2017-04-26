class DynamicAnnotation::Field < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value

  before_validation :set_annotation_type, :set_field_type

  def to_s
    s = self.value
    begin
      [
        "field_formatter_#{self.annotation.annotation_type}_#{self.field_name}",
        "field_formatter_name_#{self.field_name}",
        "field_formatter_type_#{self.field_instance.field_type}",
      ].each do |name|
        if self.respond_to?(name)
          s = self.send(name)
          break
        end
      end
    rescue
    end
    s
  end

  include Versioned

  private

  def set_annotation_type
    self.annotation_type ||= self.annotation.annotation_type
  end

  def set_field_type
    self.field_type ||= self.field_instance.field_type
  end
end
