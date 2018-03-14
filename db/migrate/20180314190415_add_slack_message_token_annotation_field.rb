class AddSlackMessageTokenAnnotationField < ActiveRecord::Migration
  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'slack_message').last
    create_field_instance annotation_type_object: at, name: 'slack_message_token', label: 'Slack Message Token', field_type_object: ft, optional: false
  end
end
