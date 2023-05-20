module Types
  class FeedTeamType < DefaultObject
    description "Feed team type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :filters, JsonString, null: true
    field :team, TeamType, null: true
    field :feed, FeedType, null: true
    field :team_id, Integer, null: true
    field :feed_id, Integer, null: true
    field :shared, Boolean, null: true
    field :requests_filters,
          JsonString,
          method: :get_requests_filters,
          null: true
  end
end
