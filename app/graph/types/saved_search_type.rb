SavedSearchType = GraphqlCrudOperations.define_default_type do
  name 'SavedSearch'
  description 'Saved search type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :title, types.String
  field :filters, JsonStringType
  field :team_id, types.Int
  field :team, TeamType

  field :filters, types.String do
    resolve -> (saved_search, _args, _ctx) {
      saved_search.filters ? saved_search.filters.to_json : '{}'
    }
  end
end
