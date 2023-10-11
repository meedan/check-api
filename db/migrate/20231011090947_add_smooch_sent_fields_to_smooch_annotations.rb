require 'sample_data'
include SampleData
class AddSmoochSentFieldsToSmoochAnnotations < ActiveRecord::Migration[6.1]
  def change
    t = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch').last
    unless at.nil?
      create_field_instance annotation_type_object: at, name: 'report_correction_sent_at', label: 'Report correction sent time', field_type_object: t, optional: true
      create_field_instance annotation_type_object: at, name: 'report_sent_at', label: 'Report sent time', field_type_object: t, optional: true
    end
  end
end
