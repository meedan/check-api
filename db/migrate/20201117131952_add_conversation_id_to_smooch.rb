class AddConversationIdToSmooch < ActiveRecord::Migration
	require 'sample_data'
  include SampleData

  def change
  	at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    create_field_instance annotation_type_object: at, name: 'smooch_conversation_id', label: 'Conversation Id', field_type_object: ft, optional: true
  end
end
