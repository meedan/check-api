class ExplainerType < DefaultObject
  description 'Explainer type'

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :url, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :user, UserType, null: true
  field :team, PublicTeamType, null: true
  field :tags, [GraphQL::Types::String, null: true], null: true
  field :trashed, GraphQL::Types::Boolean, null: true
  field :author, UserType, null: true
  field :channel, GraphQL::Types::String, null: false
end
