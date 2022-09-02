RequestType = GraphqlCrudOperations.define_default_type do
  name 'Request'
  description 'Request type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :last_submitted_at, types.String
  field :request_type, types.String
  field :content, types.String
  field :medias_count, types.Int
  field :requests_count, types.Int
  field :similar_to_request, RequestType
  field :media, MediaType
  field :feed, FeedType

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
