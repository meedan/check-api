RelationshipType = GraphQL::ObjectType.define do
  name 'Relationship'
  description 'A relationship between two items'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :dbid, types.Int
  field :target_id, types.Int
  field :source_id, types.Int

  field :target, ProjectMediaType
  field :source, ProjectMediaType
end 
