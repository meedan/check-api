SavedSearchType = GraphqlCrudOperations.define_default_type do
  name 'SavedSearch'
  description 'Saved search type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :title, types.String
  field :team_id, types.Int
  field :team, TeamType

  field :filters, types.String do
    resolve -> (saved_search, _args, _ctx) {
      saved_search.filters ? saved_search.filters.to_json : '{}'
    }
  end

  field :is_part_of_feeds, types.Boolean do
    resolve -> (saved_search, _args, _ctx) {
      Feed.where(saved_search_id: saved_search.id).exists?
    }
  end

  connection :feeds, -> { FeedType.connection_type } do
    resolve -> (saved_search, _args, _ctx) {
      Feed.where(saved_search_id: saved_search.id)
    }
  end
end
