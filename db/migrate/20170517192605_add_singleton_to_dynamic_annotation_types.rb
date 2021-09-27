class AddSingletonToDynamicAnnotationTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :dynamic_annotation_annotation_types, :singleton, :boolean, default: true
    DynamicAnnotation::AnnotationType.reset_column_information
    translation_type = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation').last
    unless translation_type.nil?
      translation_type.singleton = false
      translation_type.save!
    end
  end
end
