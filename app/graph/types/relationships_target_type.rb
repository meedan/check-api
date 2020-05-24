RelationshipsTargetType = GraphQL::ObjectType.define do
  name 'RelationshipsTarget'
  description 'The list of Target items in a Relationship.'
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :type, types.String
  connection :targets, -> { ProjectMediaType.connection_type }
end
