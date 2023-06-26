class FeedType < DefaultObject
  description "Feed type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :user_id, GraphQL::Types::Integer, null: true
  field :team_id, GraphQL::Types::Integer, null: true
  field :name, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :published, GraphQL::Types::Boolean, null: true
  field :filters, JsonString, null: true
  field :current_feed_team, FeedTeamType, null: true
  field :teams_count, GraphQL::Types::Integer, null: true
  field :requests_count, GraphQL::Types::Integer, null: true
  field :root_requests_count, GraphQL::Types::Integer, null: true
  field :tags, [String], null: false
  field :licenses, [Integer], null: false
  field :saved_search_id, GraphQL::Types::Integer, null: true
  field :team, TeamType, null: true
  field :saved_search, SavedSearchType, null: true

  field :requests, RequestType.connection_type, null: true do
    argument :request_id, GraphQL::Types::Integer, required: false
    argument :offset, GraphQL::Types::Integer, required: false
    argument :sort, GraphQL::Types::String, required: false
    argument :sort_type, GraphQL::Types::String, required: false
    # Filters
    argument :medias_count_min, GraphQL::Types::Integer, required: false
    argument :medias_count_max, GraphQL::Types::Integer, required: false
    argument :requests_count_min, GraphQL::Types::Integer, required: false
    argument :requests_count_max, GraphQL::Types::Integer, required: false
    argument :request_created_at, GraphQL::Types::String, required: false # JSON
    argument :fact_checked_by, GraphQL::Types::String, required: false
    argument :keyword, GraphQL::Types::String, required: false
  end

  def requests(**args)
    object.search(args)
  end
end
