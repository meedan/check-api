class ClusterTeamFactCheckType < DefaultObject
  description "Cluster team fact-check type: Data about a fact-check in cluster but under the scope of a team"

  implements GraphQL::Types::Relay::Node

  field :claim, GraphQL::Types::String, null: true
  field :fact_check_title, GraphQL::Types::String, null: true
  field :fact_check_summary, GraphQL::Types::String, null: true
  field :rating, GraphQL::Types::String, null: true
  field :media_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
end
