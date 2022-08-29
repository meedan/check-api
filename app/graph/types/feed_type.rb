FeedType = GraphqlCrudOperations.define_default_type do
  name 'Feed'
  description 'Feed type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :name, types.String
  field :published, types.Boolean
  field :filters, JsonStringType
  field :current_feed_team, FeedTeamType
  field :teams_count, types.Int

  connection :requests, -> { RequestType.connection_type } do
    argument :request_id, types.Int

    resolve ->(feed, args, _ctx) {
      request_id = (args['request_id'].to_i == 0 ? nil : args['request_id'].to_i)
      Request.where(request_id: request_id, feed_id: feed.id).or(Request.where(id: request_id, feed_id: feed.id)).order('requests_count DESC')
    }
  end
end
