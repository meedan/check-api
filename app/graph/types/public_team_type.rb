PublicTeamType = GraphqlCrudOperations.define_default_type do
  name 'PublicTeam'
  description 'Public team type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Team')
  field :name, !types.String
  field :subdomain, !types.String
  field :description, types.String
  field :dbid, types.Int
end
