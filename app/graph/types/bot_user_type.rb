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
  field :settings_ui_schema, types.String
  field :installation, TeamBotInstallationType
  field :default, types.Boolean

  field :settings_as_json_schema do
    type types.String
    argument :team_slug, types.String # Some settings options are team-specific

    resolve -> (bot, args, _ctx) {
      bot.settings_as_json_schema(false, args['team_slug'])
    }
  end

  field :team_author do
    type -> { TeamType }

    resolve -> (bot, _args, _ctx) {
      RecordLoader.for(Team).load(bot.team_author_id.to_i)
    }
  end
end
