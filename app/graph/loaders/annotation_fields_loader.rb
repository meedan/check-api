module Loaders
  class AnnotationFieldsLoader < GraphQL::Batch::Loader
    def perform(annotation_ids)
      fields_by_annotation = DynamicAnnotation::Field
        .includes(:field_instance, :annotation)
        .where(annotation_id: annotation_ids)
        .group_by(&:annotation_id)

      annotation_ids.each do |annotation_id|
        fulfill(annotation_id, fields_by_annotation[annotation_id] || [])
      end
    end
  end
end