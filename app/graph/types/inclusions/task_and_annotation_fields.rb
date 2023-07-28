module Types::Inclusions
  module TaskAndAnnotationFields
    extend ActiveSupport::Concern

    included do
      field :annotations, ::AnnotationUnion.connection_type, null: true do
        argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
      end

      def annotations(annotation_type:)
        object.get_annotations(annotation_type.split(",").map(&:strip))
      end

      field :annotations_count, GraphQL::Types::Int, null: true do
        argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
      end

      def annotations_count(annotation_type:)
        object.get_annotations(annotation_type.split(",").map(&:strip)).count
      end

      field :tasks, ::TaskType.connection_type, null: true do
        argument :fieldset, GraphQL::Types::String, required: false
      end

      def tasks(fieldset: nil)
        tasks = ::Task.where(
          annotation_type: "task",
          annotated_type: object.class.name,
          annotated_id: object.id
        )
        tasks = tasks.from_fieldset(fieldset) unless fieldset.blank?
        # Order tasks by order field
        ids = tasks.to_a.sort_by { |task| task.order ||= 0 }.map(&:id)
        values = []
        ids.each_with_index { |id, i| values << "(#{id}, #{i})" }
        return tasks if values.empty?
        joins = ActiveRecord::Base.send(
          :sanitize_sql_array,
          [
            "JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value",
            values.join(", "),
            "annotations"
          ]
        )
        tasks.joins(joins).order("x.order_number")
      end
    end
  end
end
