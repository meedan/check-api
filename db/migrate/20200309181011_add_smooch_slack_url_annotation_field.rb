class AddSmoochSlackUrlAnnotationField < ActiveRecord::Migration
	require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch_user').last
    create_field_instance annotation_type_object: at, name: 'smooch_user_slack_channel_url', label: 'Smooch User Slack Channel Url', field_type_object: ft, optional: false
  end
end
