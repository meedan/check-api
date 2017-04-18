class DynamicAnnotation::Field < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value

  before_validation :set_annotation_type, :set_field_type

  def to_s
    begin
      # FIXME This is hardcoded to values of 'selected' + 'other' as per the current structure of tasks.
      #       Should convert to a generic mechanism to specify value extractors for different dynamic field types.
      value = JSON.parse(self.value)
      answer = value['selected']
      answer.insert(-1, value['other']) if !value['other'].blank?
      v = answer.to_sentence(locale: I18n.locale)
    rescue
      v = self.value
    end
    v
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
