# require "inclusions/task_and_annotation_fields"

class SourceType < DefaultObject
  # include TaskAndAnnotationFields
  # module TaskAndAnnotationFields
    # Inject field definitions into class
    # def self.included(base)
      # base.class_eval do
        # .field_annotations
        field :annotations,
              AnnotationUnion.connection_type,
              null: true do
          argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
        end

        # .field_annotations_count
        field :annotations_count, GraphQL::Types::Int, null: true do
          argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
        end

        # .field_tasks
        field :tasks, TaskType.connection_type, null: true do
          argument :fieldset, GraphQL::Types::String, required: false
        end
      # end
    # end

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
  # end

  description "Source type"

  implements NodeIdentification.interface

  field :image, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: false
  field :name, GraphQL::Types::String, null: false
  field :dbid, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :lock_version, GraphQL::Types::Int, null: true
  field :medias_count, GraphQL::Types::Int, null: true
  field :accounts_count, GraphQL::Types::Int, null: true
  field :overridden, JsonString, null: true
  field :archived, GraphQL::Types::Int, null: true

  field :accounts, AccountType.connection_type, null: true

  field :account_sources,
        AccountSourceType.connection_type,
        null: true

  def account_sources
    object.account_sources.order(id: :asc)
  end

  field :medias,
        ProjectMediaType.connection_type,
        null: true

  def medias
    object.media
  end

  field :medias_count,
        Integer,
        null: true,
        resolve: ->(source, _args, _ctx) { source.medias_count }

  field :collaborators, UserType.connection_type, null: true
end
