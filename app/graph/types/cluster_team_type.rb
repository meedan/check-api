class ClusterTeamType < DefaultObject
  description "Cluster team type: Data about a cluster but under the scope of a team"

  implements GraphQL::Types::Relay::Node

  field :team, PublicTeamType, null: true
  field :last_request_date, GraphQL::Types::Int, null: true
  field :media_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true

  field :fact_checks, ClusterTeamFactCheckType.connection_type, null: true
end
