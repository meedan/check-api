VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'Version type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('PaperTrail::Version')
  field :item_type, types.String
  field :item_id, types.String
  field :event, types.String

end
