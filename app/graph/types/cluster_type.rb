class ClusterType < DefaultObject
  description "Cluster type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :team_ids, [GraphQL::Types::Int, null: true], null: true
  field :channels, [GraphQL::Types::Int, null: true], null: true
  field :media_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
  field :fact_checks_count, GraphQL::Types::Int, null: true
  field :center, ProjectMediaType, null: true

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

  field :teams, TeamType.connection_type, null: true

  def teams
    Team.where(id: object.team_ids)
  end
end
