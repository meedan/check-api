require 'sample_data'
include SampleData
class CreateReviewAndSuggestionFieldsForTasks < ActiveRecord::Migration[4.2]
  def change
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    Task.task_types.each do |type|
      at = DynamicAnnotation::AnnotationType.where(annotation_type: "task_response_#{type}").last
      next if at.nil?
      create_field_instance annotation_type_object: at, name: "suggestion_#{type}", label: 'Suggestion', field_type_object: json, optional: true
      create_field_instance annotation_type_object: at, name: "review_#{type}", label: 'Review', field_type_object: json, optional: true
    end
  end
end
