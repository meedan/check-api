TeamBotInstallationType = GraphqlCrudOperations.define_default_type do
  name 'TeamBotInstallation'
  description 'Team Bot Installation type'

  interfaces [NodeIdentification.interface]

  field :team_bot do
    type -> { TeamBotType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(TeamBot).load(team_bot_installation.team_bot_id)
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (team_bot_installation, _args, _ctx) {
      RecordLoader.for(Team).load(team_bot_installation.team_id)
    }
  end
end 
