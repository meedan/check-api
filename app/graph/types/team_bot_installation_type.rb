TeamBotInstallationType = GraphqlCrudOperations.define_default_type do
  name 'TeamBotInstallation'
  description 'Team Bot Installation type'

  interfaces [NodeIdentification.interface]

  field :json_settings, types.String

  field :bot_user do
    type -> { BotUserType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(BotUser).load(team_bot_installation.user_id)
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(Team).load(team_bot_installation.team_id)
    }
  end
end
