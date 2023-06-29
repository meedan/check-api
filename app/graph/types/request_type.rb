class RequestType < DefaultObject
  description "Request type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :last_submitted_at, GraphQL::Types::Int, null: true
  field :request_type, GraphQL::Types::String, null: true
  field :content, GraphQL::Types::String, null: true
  field :last_called_webhook_at, GraphQL::Types::String, null: true
  field :fact_checked_by, GraphQL::Types::String, null: true
  field :subscribed, GraphQL::Types::Boolean, null: true
  field :medias_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
  field :subscriptions_count, GraphQL::Types::Int, null: true
  field :project_medias_count, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :similar_to_request, RequestType, null: true
  field :media_type, GraphQL::Types::String, null: true

  field :feed, FeedType, null: true

  def feed
    RecordLoader.for(Feed).load(object.feed_id)
  end

  field :media, MediaType, null: true

  def media
    RecordLoader.for(Media).load(object.media_id)
  end

  field :medias, MediaType.connection_type, null: true

  field :similar_requests,
        RequestType.connection_type,
        null: true do
    argument :media_id, GraphQL::Types::Int, required: false, camelize: false
  end

  def similar_requests(**args)
    requests =
      object.similar_requests.where(
        webhook_url: nil,
        last_called_webhook_at: nil
      )
    requests = requests.where(media_id: args[:media_id].to_i) unless args[
      :media_id
    ].blank?
    requests
  end
end
