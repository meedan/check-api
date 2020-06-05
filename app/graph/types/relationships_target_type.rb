RelationshipsTargetType = GraphQL::ObjectType.define do
  name 'RelationshipsTarget'
  description 'The list of target items in a relationship.'
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :type, types.String # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
  connection :targets, -> { ProjectMediaType.connection_type }
end
