class RemoveFetchAnnotationType < ActiveRecord::Migration
  def change
    DynamicAnnotation::AnnotationType.where(annotation_type: 'fetch').destroy_all
  end
end
