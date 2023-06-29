class VersionType < DefaultObject
  description "Version type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :item_type, GraphQL::Types::String, null: true
  field :item_id, GraphQL::Types::String, null: true
  field :event, GraphQL::Types::String, null: true
  field :event_type, GraphQL::Types::String, null: true
  field :object_after, GraphQL::Types::String, null: true
  field :meta, GraphQL::Types::String, null: true
  field :object_changes_json, GraphQL::Types::String, null: true
  field :associated_graphql_id, GraphQL::Types::String, null: true

  field :user, UserType, null: true
  field :annotation, "AnnotationType", null: true
  field :task, "TaskType", null: true
  field :tag, "TagType", null: true

  def tag
    Tag.find(object.annotation.id) unless object.annotation.nil?
  end
end
