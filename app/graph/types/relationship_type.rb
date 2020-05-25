RelationshipType = GraphQL::ObjectType.define do
  name 'Relationship'
  description 'A relationship between two items.'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :dbid, types.Int, 'Database id of this record'
  field :target_id, types.Int, 'Relationship target (id only)'
  field :source_id, types.Int, 'Relationship source (id only)'
  field :permissions, types.String, 'CRUD permissions for current user'
  field :relationship_type, types.String

  field :target, ProjectMediaType, 'Relationship target'
  field :source, ProjectMediaType, 'Relationship source'
end
