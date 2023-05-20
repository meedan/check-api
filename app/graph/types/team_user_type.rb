module Types
  class TeamUserType < DefaultObject
    description "TeamUser type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :user_id, Integer, null: true
    field :team_id, Integer, null: true
    field :status, String, null: true
    field :role, String, null: true
    field :permissions, String, null: true

    field :team, TeamType, null: true

    def team
      object.team
    end

    field :user, UserType, null: true

    def user
      object.user
    end

    field :invited_by, UserType, null: true

    def invited_by
      User.find_by_id(object.invited_by_id)
    end
  end
end
