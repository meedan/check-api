RelationshipType = GraphQL::ObjectType.define do
  name 'Relationship'
  description 'A relationship between two items.'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :relationship_type, types.String, 'Relationship type'
  field :target_id, types.Int, 'Relationship target item database id'
  field :target, ProjectMediaType, 'Relationship target'
  field :source_id, types.Int, 'Relationship source item database id'
  field :source, ProjectMediaType, 'Relationship source'
  field :dbid, types.Int, 'Database id of this record'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
end
