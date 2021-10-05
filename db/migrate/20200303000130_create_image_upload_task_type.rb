class CreateImageUploadTaskType < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    image = create_field_type field_type: 'image', label: 'Image'
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    at = create_annotation_type annotation_type: 'task_response_image_upload', label: 'Task Response Image Upload'
    create_field_instance annotation_type_object: at, name: 'response_image_upload', label: 'Response', field_type_object: image, optional: true
    create_field_instance annotation_type_object: at, name: 'suggestion_image_upload', label: 'Suggestion', field_type_object: json, optional: true
    create_field_instance annotation_type_object: at, name: 'review_image_upload', label: 'Review', field_type_object: json, optional: true
  end
end
