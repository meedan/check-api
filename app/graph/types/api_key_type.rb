class ApiKeyType < DefaultObject
  description "ApiKey type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :access_token, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :application, GraphQL::Types::String, null: true
  field :expire_at, GraphQL::Types::String, null: true

  field :team, TeamType, null: true
  field :user, UserType, null: true
end
