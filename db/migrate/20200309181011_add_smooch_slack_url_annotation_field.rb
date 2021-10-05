class AddSmoochSlackUrlAnnotationField < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch_user').last
    create_field_instance annotation_type_object: at, name: 'smooch_user_slack_channel_url', label: 'Smooch User Slack Channel Url', field_type_object: ft, optional: true
  end
end
