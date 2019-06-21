TeamBotType = GraphqlCrudOperations.define_default_type do
  name 'TeamBot'
  description 'Team Bot type'

  interfaces [NodeIdentification.interface]

  field :avatar, types.String
  field :name, types.String
  field :description, types.String
  field :version, types.String
  field :source_code_url, types.String
  field :role, types.String
  field :identifier, types.String
  field :dbid, types.Int
  field :limited, types.Boolean
  field :installed, types.Boolean
  field :installations_count, types.Int
  field :settings_as_json_schema, types.String
  field :settings_ui_schema, types.String
  field :installation, TeamBotInstallationType

  field :team_author do
    type -> { TeamType }

    resolve -> (team_bot, _args, _ctx) {
      RecordLoader.for(Team).load(team_bot.team_author_id)
    }
  end
end 
