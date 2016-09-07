UserType = GraphQL::ObjectType.define do
  name 'User'
  description 'User type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('User')
  field :email, types.String
  field :provider, types.String
  field :uuid, types.String
  field :profile_image, types.String
  field :login, types.String
  field :name, types.String
  field :current_team_id, types.Int

  field :source do
    type SourceType
    resolve -> (user, _args, _ctx) do
      user.source
    end
  end

  field :current_team do
    type TeamType
    resolve -> (user, _args, _ctx) do
      user.current_team
    end
  end

  connection :teams, -> { TeamType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.teams
    }
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.team_users
    }
  end
end
