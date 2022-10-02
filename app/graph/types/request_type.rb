RequestType = GraphqlCrudOperations.define_default_type do
  name 'Request'
  description 'Request type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :last_submitted_at, types.String
  field :request_type, types.String
  field :content, types.String
  field :last_called_webhook_at, types.String
  field :fact_checked_by, types.String
  field :subscribed, types.Boolean
  field :medias_count, types.Int
  field :requests_count, types.Int
  field :subscriptions_count, types.Int
  field :title, types.String
  field :similar_to_request, RequestType

  field :feed do
    type -> { FeedType }

    resolve -> (request, _args, _ctx) {
      RecordLoader.for(Feed).load(request.feed_id)
    }
  end

  field :media do
    type -> { MediaType }

    resolve -> (request, _args, _ctx) {
      RecordLoader.for(Media).load(request.media_id)
    }
  end

  connection :medias, MediaType.connection_type

  connection :similar_requests, -> { RequestType.connection_type } do
    argument :media_id, types.Int

    resolve ->(request, args, _ctx) {
      requests = request.similar_requests
      requests = requests.where(media_id: args['media_id'].to_i) unless args['media_id'].blank?
      requests
    }
  end
end
