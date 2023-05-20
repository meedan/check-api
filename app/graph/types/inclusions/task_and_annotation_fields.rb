module TaskAndAnnotationFields
  # Inject field definitions into class
  def self.included(base)
    base.class_eval do
      # .field_annotations
      field :annotations,
            Types::AnnotationUnion.connection_type,
            null: true,
            connection: true do
        argument :annotation_type, String, required: true
      end

      # .field_annotations_count
      field :annotations_count, Integer, null: true do
        argument :annotation_type, String, required: true
      end

      # .field_tasks
      field :tasks, Types::TaskType.connection_type, null: true, connection: true do
        argument :fieldset, String, required: false
      end
    end
  end

  # For field: :tasks, imported by .field_tasks
  def tasks(**args)
    tasks =
      Task.where(
        annotation_type: "task",
        annotated_type: object.class.name,
        annotated_id: object.id
      )
    tasks = tasks.from_fieldset(args[:fieldset]) unless args["fieldset"].blank?
    # Order tasks by order field
    ids = tasks.to_a.sort_by { |task| task.order ||= 0 }.map(&:id)
    values = []
    ids.each_with_index { |id, i| values << "(#{id}, #{i})" }
    return tasks if values.empty?
    joins =
      ActiveRecord::Base.send(
        :sanitize_sql_array,
        [
          "JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value",
          values.join(", "),
          "annotations"
        ]
      )
    tasks.joins(joins).order("x.order_number")
  end

  # For field: :annotations, imported by .field_annotations
  def annotations(**args)
    object.get_annotations(args[:annotation_type].split(",").map(&:strip))
  end

  # For field: :annotations_count, imported by .field_annotations_count
  def annotations_count(**args)
    object.get_annotations(args[:annotation_type].split(",").map(&:strip)).count
  end
end
