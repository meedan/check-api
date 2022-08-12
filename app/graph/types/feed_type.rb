FeedType = GraphqlCrudOperations.define_default_type do
  name 'Feed'
  description 'Feed type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :name, types.String
  field :published, types.Boolean
  field :filters, JsonStringType
  field :current_feed_team, FeedTeamType
end
