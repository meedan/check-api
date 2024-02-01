class RootLevelType < BaseObject
  description "Unassociated root object queries"

  implements GraphQL::Types::Relay::Node

  global_id_field :id

  field :current_user, MeType, null: true

  def current_user
    User.current
  end

  field :current_team, TeamType, null: true

  def current_team
    Team.current
  end

  field :team_bots_listed, BotUserType.connection_type, null: true

  def team_bots_listed
    BotUser.listed
  end
end
