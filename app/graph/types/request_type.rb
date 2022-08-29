RequestType = GraphqlCrudOperations.define_default_type do
  name 'Request'
  description 'Request type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :last_submitted, types.String
  field :request_type, types.String
  field :content, types.String
  field :medias_count, types.Int
  field :requests_count, types.Int
  field :similar_to_request, RequestType
  field :media, MediaType

  connection :medias, MediaType.connection_type
  connection :similar_requests, RequestType.connection_type
end
