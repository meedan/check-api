class FeedType < DefaultObject
  description "Feed type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :name, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :published, GraphQL::Types::Boolean, null: true
  field :filters, JsonStringType, null: true
  field :current_feed_team, FeedTeamType, null: true
  field :teams_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
  field :root_requests_count, GraphQL::Types::Int, null: true
  field :tags, [GraphQL::Types::String, null: true], null: true
  field :licenses, [GraphQL::Types::Int, null: true], null: true
  field :media_saved_search_id, GraphQL::Types::Int, null: true
  field :article_saved_search_id, GraphQL::Types::Int, null: true
  field :discoverable, GraphQL::Types::Boolean, null: true
  field :last_clusterized_at, GraphQL::Types::String, null: true
  field :user, UserType, null: true

  field :team, PublicTeamType, null: true
  field :media_saved_search, SavedSearchType, null: true
  field :media_saved_search_was, SavedSearchType, null: true
  field :article_saved_search, SavedSearchType, null: true
  field :article_saved_search_was, SavedSearchType, null: true

  field :requests, RequestType.connection_type, null: true do
    argument :request_id, GraphQL::Types::Int, required: false, camelize: false
    argument :offset, GraphQL::Types::Int, required: false
    argument :sort, GraphQL::Types::String, required: false
    argument :sort_type, GraphQL::Types::String, required: false, camelize: false
    # Filters
    argument :medias_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :medias_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :request_created_at, GraphQL::Types::String, required: false, camelize: false # JSON
    argument :fact_checked_by, GraphQL::Types::String, required: false, camelize: false
    argument :keyword, GraphQL::Types::String, required: false
  end

  def requests(**args)
    object.search(args)
  end

  field :feed_invitations, FeedInvitationType.connection_type, null: false

  def feed_invitations
    ability = context[:ability] || Ability.new
    return FeedInvitation.none unless ability.can?(:read_feed_invitations, object)
    object.feed_invitations
  end

  field :teams, PublicTeamType.connection_type, null: false
  field :feed_teams, FeedTeamType.connection_type, null: false
  field :data_points, [GraphQL::Types::Int, null: true], null: true

  field :clusters_count, GraphQL::Types::Int, null: true do
    # Filters
    argument :team_ids, [GraphQL::Types::Int, null: true], required: false, default_value: nil, camelize: false
    argument :channels, [GraphQL::Types::Int, null: true], required: false, default_value: nil, camelize: false
    argument :medias_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :medias_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :last_request_date, GraphQL::Types::String, required: false, camelize: false # JSON
    argument :media_type, [GraphQL::Types::String, null: true], required: false, camelize: false
  end

  def clusters_count(**args)
    object.clusters_count(args)
  end

  field :clusters, ClusterType.connection_type, null: true do
    argument :offset, GraphQL::Types::Int, required: false, default_value: 0
    argument :sort, GraphQL::Types::String, required: false, default_value: 'title'
    argument :sort_type, GraphQL::Types::String, required: false, camelize: false, default_value: 'ASC'
    # Filters
    argument :team_ids, [GraphQL::Types::Int, null: true], required: false, default_value: nil, camelize: false
    argument :channels, [GraphQL::Types::Int, null: true], required: false, default_value: nil, camelize: false
    argument :medias_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :medias_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_min, GraphQL::Types::Int, required: false, camelize: false
    argument :requests_count_max, GraphQL::Types::Int, required: false, camelize: false
    argument :last_request_date, GraphQL::Types::String, required: false, camelize: false # JSON
    argument :media_type, [GraphQL::Types::String, null: true], required: false, camelize: false
  end

  def clusters(**args)
    sort = args[:sort].to_s
    order = [:title, :media_count, :requests_count, :fact_checks_count, :last_request_date].include?(sort.downcase.to_sym) ? sort.downcase.to_sym : :title
    order_type = args[:sort_type].to_s.downcase.to_sym == :desc ? :desc : :asc
    object.filtered_clusters(args).offset(args[:offset].to_i).order(order => order_type)
  end

  # Given a project media ID, return the cluster it belongs to, in the scope of this feed
  field :cluster, ClusterType, null: true do
    argument :project_media_id, GraphQL::Types::Int, required: true, camelize: false
  end

  def cluster(project_media_id:)
    cluster = ClusterProjectMedia.joins(:cluster).where('clusters.feed_id' => object.id, 'cluster_project_medias.project_media_id' => project_media_id.to_i).first&.cluster
    return nil if cluster.nil?
    ability = context[:ability] || Ability.new
    return nil unless ability.can?(:read, object)
    cluster
  end
end
