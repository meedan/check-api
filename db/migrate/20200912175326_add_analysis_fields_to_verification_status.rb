class AddAnalysisFieldsToVerificationStatus < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    create_field_instance annotation_type_object: at, name: 'title', label: 'Title', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'content', label: 'Content', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'published_article_url', label: 'Published Article URL', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'date_published', label: 'Date Published', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'raw', label: 'Raw', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'external_id', label: 'External ID', field_type_object: ft, optional: true
  end
end
