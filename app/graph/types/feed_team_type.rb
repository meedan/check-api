FeedTeamType = GraphqlCrudOperations.define_default_type do
  name 'FeedTeam'
  description 'Feed team type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :filters, JsonStringType
  field :team, TeamType
  field :feed, FeedType
  field :team_id, types.Int
  field :feed_id, types.Int
  field :shared, types.Boolean
  field :requests_filters, JsonStringType, property: :get_requests_filters
end
