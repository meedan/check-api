class ClusterType < DefaultObject
  description "Cluster type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :size, GraphQL::Types::Int, null: true
  field :team_names, [GraphQL::Types::String], null: true
  field :fact_checked_by_team_names, JsonString, null: true
  field :requests_count, GraphQL::Types::Int, null: true

  field :first_item_at, GraphQL::Types::Int, null: true

  def first_item_at
    object.first_item_at.to_i
  end

  field :last_item_at, GraphQL::Types::Int, null: true

  def last_item_at
    object.last_item_at.to_i
  end

  field :items,
        ProjectMediaType.connection_type,
        null: true do
    argument :feed_id, GraphQL::Types::Int, required: true, camelize: false
  end

  def items(**args)
    Cluster.find_if_can(object.id, context[:ability])
    feed = Feed.find_if_can(args[:feed_id].to_i, context[:ability])
    object.project_medias.joins(:team).where("teams.id" => feed.team_ids)
  end

  field :claim_descriptions,
        ClaimDescriptionType.connection_type,
        null: true do
    argument :feed_id, GraphQL::Types::Int, required: true, camelize: false
  end

  def claim_descriptions(**args)
    Cluster.find_if_can(object.id, context[:ability])
    feed = Feed.find_if_can(args[:feed_id].to_i, context[:ability])
    ClaimDescription.joins(project_media: :team).where(
      "project_medias.cluster_id" => object.id,
      "teams.id" => feed.team_ids
    )
  end
end
