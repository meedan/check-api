FeedType = GraphqlCrudOperations.define_default_type do
  name 'Feed'
  description 'Feed type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :user_id, types.Int
  field :name, types.String
  field :description, types.String
  field :published, types.Boolean
  field :filters, JsonStringType
  field :current_feed_team, FeedTeamType
  field :teams_count, types.Int
  field :requests_count, types.Int
  field :root_requests_count, types.Int
  field :tags, JsonStringType
  field :licenses, types[types.Int]
  field :saved_search_id, types.Int
  field :team_id, types.Int

  field :user do
    type -> { UserType }

    resolve -> (feed, _args, ctx) {
      RecordLoader.for(User).load(feed.user_id).then do |user|
        ability = ctx[:ability] || Ability.new
        user if ability.can?(:read, user)
      end
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (feed, _args, _ctx) {
      RecordLoader.for(Team).load(feed.team_id)
    }
  end

  field :saved_search do
    type -> { SavedSearchType }

    resolve -> (feed, _args, _ctx) {
      RecordLoader.for(SavedSearch).load(feed.saved_search_id)
    }
  end

  connection :requests, -> { RequestType.connection_type } do
    argument :request_id, types.Int
    argument :offset, types.Int
    argument :sort, types.String
    argument :sort_type, types.String
    # Filters
    argument :medias_count_min, types.Int
    argument :medias_count_max, types.Int
    argument :requests_count_min, types.Int
    argument :requests_count_max, types.Int
    argument :request_created_at, types.String # JSON
    argument :fact_checked_by, types.String
    argument :keyword, types.String

    resolve ->(feed, args, _ctx) {
      feed.search(args)
    }
  end
end
