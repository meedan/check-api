module Types
  class FeedType < DefaultObject
    description 'Feed type'

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :name, String, null: true
    field :published, Boolean, null: true
    field :filters, JsonString, null: true
    field :current_feed_team, FeedTeamType, null: true
    field :teams_count, Integer, null: true
    field :requests_count, Integer, null: true
    field :root_requests_count, Integer, null: true

    field :requests, RequestType.connection_type, null: true, connection: true do
      argument :request_id, Integer, required: false
      argument :offset, Integer, required: false
      argument :sort, String, required: false
      argument :sort_type, String, required: false
      # Filters
      argument :medias_count_min, Integer, required: false
      argument :medias_count_max, Integer, required: false
      argument :requests_count_min, Integer, required: false
      argument :requests_count_max, Integer, required: false
      argument :request_created_at, String, required: false # JSON
      argument :fact_checked_by, String, required: false
      argument :keyword, String, required: false
    end

    def requests(**args)
      object.search(args)
    end
  end
end
