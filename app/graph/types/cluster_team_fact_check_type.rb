class ClusterTeamFactCheckType < DefaultObject
  description "Cluster team fact-check type: Data about a fact-check in cluster but under the scope of a team"

  implements GraphQL::Types::Relay::Node

  field :claim_description, ClaimDescriptionType, null: true
  field :fact_check, FactCheckType, null: true
  field :rating, GraphQL::Types::String, null: true
  field :media_count, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
end
