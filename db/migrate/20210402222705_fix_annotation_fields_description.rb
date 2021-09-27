class FixAnnotationFieldsDescription < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:fix_annotation_fields_description:last_id', DynamicAnnotation::Field.last&.id || 0)
  end
end
