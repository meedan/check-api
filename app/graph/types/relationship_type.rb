RelationshipType = GraphQL::ObjectType.define do
  name 'Relationship'
  description 'A relationship between two items.'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :dbid, types.Int, 'Database id of this record'
  field :target_id, types.Int
  field :source_id, types.Int
  field :permissions, types.String, 'CRUD permissions for current user'
  field :relationship_type, types.String

  field :target, ProjectMediaType
  field :source, ProjectMediaType
end
