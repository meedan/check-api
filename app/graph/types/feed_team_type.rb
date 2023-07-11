class FeedTeamType < DefaultObject
  description "Feed team type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :filters, JsonStringType, null: true
  field :saved_search_id, GraphQL::Types::Int, null: true
  field :team, TeamType, null: true
  field :feed, FeedType, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :feed_id, GraphQL::Types::Int, null: true
  field :shared, GraphQL::Types::Boolean, null: true
  field :requests_filters,
        JsonStringType,
        method: :get_requests_filters,
        null: true
  field :saved_search, SavedSearchType, null: true
end
