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
  field :requests_count, types.Int
  field :root_requests_count, types.Int

  connection :requests, -> { RequestType.connection_type } do
    argument :request_id, types.Int
    argument :offset, types.Int
    argument :sort, types.String
    argument :sort_type, types.String
    # Filters
    argument :medias_count_min, types.Int
    argument :medias_count_max, types.Int

    resolve ->(feed, args, _ctx) {
      request_id = (args['request_id'].to_i == 0 ? nil : args['request_id'].to_i)

      query = Request.where(request_id: request_id, feed_id: feed.id)
      query = query.or(Request.where(id: request_id, feed_id: feed.id)) unless request_id.nil?

      # Filters
      query = query.where('medias_count >= ?', args['medias_count_min'].to_i) unless args['medias_count_min'].blank?
      query = query.where('medias_count <= ?', args['medias_count_max'].to_i) unless args['medias_count_max'].blank?

      # Sort
      sort = {
        'requests' => 'requests_count',
        'medias' => 'medias_count',
        'last_submitted' => 'last_submitted_at',
        'subscriptions' => 'subscriptions_count',
        'media_type' => 'medias.type',
        'fact_checked_by' => 'fact_checked_by_count',
        'fact_checks' => 'project_medias_count'
      }[args['sort'].to_s] || 'last_submitted_at'
      sort_type = args['sort_type'].to_s.downcase == 'asc' ? 'ASC' : 'DESC'
      query = query.joins(:media) if sort == 'medias.type'

      query.order(sort => sort_type).offset(args['offset'].to_i)
    }
  end
end
