class TeamUserType < DefaultObject
  description "TeamUser type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :status, GraphQL::Types::String, null: true
  field :role, GraphQL::Types::String, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :last_active_at, GraphQL::Types::Int, null: true
  field :team, TeamType, null: true
  field :user, UserType, null: true
  field :invited_by, UserType, null: true

  def invited_by
    User.find_by_id(object.invited_by_id)
  end
end
