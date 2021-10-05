class RemoveFetchAnnotationType < ActiveRecord::Migration[4.2]
  def change
    DynamicAnnotation::AnnotationType.where(annotation_type: 'fetch').destroy_all
  end
end
