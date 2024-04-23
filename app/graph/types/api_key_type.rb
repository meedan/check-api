class ApiKeyType < DefaultObject
  description "ApiKey type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true

  field :team, PublicTeamType, null: true
end
