class AddAnalysisFieldFileTitleToVerificationStatus < ActiveRecord::Migration[5.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    create_field_instance annotation_type_object: at, name: 'file_title', label: 'Title', field_type_object: ft, optional: true
  end
end
