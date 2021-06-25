class CreateAnalysisAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Analysis', { 'Text' => ['Text', false] })
    type = DynamicAnnotation::AnnotationType.where(annotation_type: 'analysis').last
    unless type.nil?
      type.singleton = true
      type.save!
    end
  end
end
