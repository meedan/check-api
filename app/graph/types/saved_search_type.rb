SavedSearchType = GraphqlCrudOperations.define_default_type do
  name 'SavedSearch'
  description 'Saved search type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :title, types.String
  field :filters, JsonStringType
  field :team_id, types.Int
  field :team, TeamType
end
