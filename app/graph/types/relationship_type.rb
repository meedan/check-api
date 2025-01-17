class RelationshipType < BaseObject
  description "A relationship between two items"
  implements GraphQL::Types::Relay::Node

  global_id_field :id

  field :dbid, GraphQL::Types::Int, null: true
  field :target_id, GraphQL::Types::Int, null: true
  field :source_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :relationship_type, GraphQL::Types::String, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :confirmed_at, GraphQL::Types::Int, null: true
  field :weight, GraphQL::Types::Float, null: true
  field :source_field, GraphQL::Types::String, null: true
  field :target_field, GraphQL::Types::String, null: true
  field :model, GraphQL::Types::String, null: true

  field :target, ProjectMediaType, null: true
  field :source, ProjectMediaType, null: true
  field :user, UserType, null: true
  field :confirmed_by, UserType, null: true

  def confirmed_by
    User.find_by_id(object.confirmed_by)
  end
end
