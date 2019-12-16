require 'sample_data'
include SampleData

class CreateArchiverAnnotationAndFields < ActiveRecord::Migration
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'archiver').first || create_annotation_type(annotation_type: 'archiver', label: 'Archivers')
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last

    name = 'perma_cc_response'
    create_field_instance annotation_type_object: at, name: name, label: name.titleize, field_type_object: json, optional: true unless DynamicAnnotation::FieldInstance.where(name: name).exists?

    Bot::Keep.archiver_annotation_types.each do |type|
      DynamicAnnotation::FieldInstance.where(name: "#{type}_response").last.update_columns(optional: true)
    end
  end
end
