BotUserType = GraphqlCrudOperations.define_default_type do
  name 'BotUser'
  description 'Bot User type'

  interfaces [NodeIdentification.interface]

  field :avatar, types.String
  field :name, types.String
  field :get_description, types.String
  field :get_version, types.String
  field :get_source_code_url, types.String
  field :get_role, types.String
  field :identifier, types.String
  field :login, types.String
  field :dbid, types.Int
  field :installed, types.Boolean
  field :installations_count, types.Int
  field :settings_as_json_schema, types.String
  field :settings_ui_schema, types.String
  field :installation, TeamBotInstallationType

  field :team_author do
    type -> { TeamType }

    resolve -> (bot, _args, _ctx) {
      RecordLoader.for(Team).load(bot.team_author_id.to_i)
    }
  end
end
