class RelationshipType < BaseObject
  description "A relationship between two items"
  implements NodeIdentification.interface

  global_id_field :id

  field :dbid, GraphQL::Types::Int, null: true
  field :target_id, GraphQL::Types::Int, null: true
  field :source_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :relationship_type, GraphQL::Types::String, null: true

  field :target, ProjectMediaType, null: true
  field :source, ProjectMediaType, null: true
end
