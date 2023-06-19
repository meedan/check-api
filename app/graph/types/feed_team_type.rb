FeedTeamType = GraphqlCrudOperations.define_default_type do
  name 'FeedTeam'
  description 'Feed team type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :saved_search_id, types.Int
  field :team, TeamType
  field :feed, FeedType
  field :team_id, types.Int
  field :feed_id, types.Int
  field :shared, types.Boolean
  field :requests_filters, JsonStringType, property: :get_requests_filters
  instance_exec :feed_team, &GraphqlCrudOperations.field_saved_search
end
