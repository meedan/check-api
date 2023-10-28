class AddSmoochMessageIdField < ActiveRecord::Migration[6.1]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    create_field_instance annotation_type_object: at, name: 'smooch_message_id', label: 'Message Id', field_type_object: ft, optional: true
    execute %{CREATE UNIQUE INDEX smooch_request_message_id_unique_id ON dynamic_annotation_fields (value) WHERE field_name = 'smooch_message_id' AND value <> '' AND value <> '""'}
  end
end
