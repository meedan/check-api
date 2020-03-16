class AddSmoochSlackUrlAnnotationField < ActiveRecord::Migration
	require 'sample_data'
  include SampleData

  def change
  	ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'smooch').last
    create_field_instance annotation_type_object: at, name: 'smooch_slack_url', label: 'Smooch Slack Url', field_type_object: ft, optional: false
  end
end
