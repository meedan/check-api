require 'sample_data'
include SampleData
class CreateMemebusterAnnotation < ActiveRecord::Migration[4.2]
  def change
    text = DynamicAnnotation::FieldType.where(field_type: 'text').last
    image = DynamicAnnotation::FieldType.where(field_type: 'image_path').last
    datetime = DynamicAnnotation::FieldType.where(field_type: 'datetime').last
    at = create_annotation_type annotation_type: 'memebuster', label: 'Meme Generator Settings'
    create_field_instance annotation_type_object: at, name: 'memebuster_image', label: 'Image', field_type_object: image, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_headline', label: 'Headline', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_body', label: 'Body', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_status', label: 'Status', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_overlay', label: 'Overlay Color', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_operation', label: 'Operation', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'memebuster_published_at', label: 'Published', field_type_object: datetime, optional: true
  end
end
