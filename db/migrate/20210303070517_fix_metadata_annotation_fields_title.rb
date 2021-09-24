class FixMetadataAnnotationFieldsTitle < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_metadata_annotation_fields_title:last_id', DynamicAnnotation::Field.last&.id || 0)
  end
end
