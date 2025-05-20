class FeedTeamType < DefaultObject
  description "Feed team type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :filters, JsonStringType, null: true
  field :saved_search_id, GraphQL::Types::Int, null: true, method: :media_saved_search_id
  field :team, PublicTeamType, null: true
  field :feed, FeedType, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :feed_id, GraphQL::Types::Int, null: true
  field :shared, GraphQL::Types::Boolean, null: true
  field :requests_filters, JsonStringType, null: true

  def requests_filters
    object.get_requests_filters
  end

  field :saved_search, SavedSearchType, null: true, method: :media_saved_search
  field :saved_search_was, SavedSearchType, null: true
end
