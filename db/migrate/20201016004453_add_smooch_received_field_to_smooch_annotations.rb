require 'sample_data'
include SampleData
class AddSmoochReceivedFieldToSmoochAnnotations < ActiveRecord::Migration
  def change
    t = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch').last
    unless at.nil?
      create_field_instance annotation_type_object: at, name: 'smooch_report_received', label: 'Last time the requestor received a report for this request', field_type_object: t, optional: true
    end
  end
end
