RelationshipsSourceType = GraphQL::ObjectType.define do
  name 'RelationshipsSource'
  description 'The source of a relationship'
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :source, ProjectMediaType
  field :type, types.String
  field :relationship_id, types.Int
  connection :siblings, -> { ProjectMediaType.connection_type }
end
