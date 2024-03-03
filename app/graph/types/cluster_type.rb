class ClusterType < DefaultObject
  description "Cluster type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :team_ids, [GraphQL::Types::Int, null: true], null: true
  field :channels, [GraphQL::Types::Int, null: true], null: true
  field :media_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true

  field :fact_checks_count, GraphQL::Types::Int, null: true

  def fact_checks_count
    object.feed.data_points.to_a.include?(1) ? object.fact_checks_count : nil
  end

  field :center, ProjectMediaType, null: true

  def center
    RecordLoader
      .for(ProjectMedia)
      .load(object.project_media_id)
  end

  field :first_item_at, GraphQL::Types::Int, null: true

  def first_item_at
    object.first_item_at.to_i
  end

  field :last_item_at, GraphQL::Types::Int, null: true

  def last_item_at
    object.last_item_at.to_i
  end

  field :last_request_date, GraphQL::Types::Int, null: true

  def last_request_date
    object.last_request_date.to_i
  end

  field :last_fact_check_date, GraphQL::Types::Int, null: true

  def last_fact_check_date
    object.last_fact_check_date.to_i
  end

  field :teams, PublicTeamType.connection_type, null: true

  def teams
    Team.where(id: object.team_ids)
  end
end
