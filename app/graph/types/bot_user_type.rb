BotUserType = GraphqlCrudOperations.define_default_type do
  name 'BotUser'
  description 'A type of User that represents a bot.'

  interfaces [NodeIdentification.interface]

  field :avatar, types.String, 'Picture' # TODO Merge with User.profile_image?
  field :name, types.String, 'Name'
  field :get_description, types.String, 'Description' # TODO Rename to 'description'
  field :get_version, types.String, 'Version' # TODO Rename to 'version'
  field :get_source_code_url, types.String, 'Source code URL' # TODO Rename to 'source_code_url'
  field :get_role, types.String, 'Role of the bot when added to a team'
  field :identifier, types.String, 'Machine name' # TODO Merge with BotUser.login?
  field :login, types.String, 'Login name'
  field :dbid, types.Int, 'Database id of this record'
  field :installed, types.Boolean, 'Is the bot approved for Check-wide use?'
  field :installations_count, types.Int, 'Count of team installations'
  field :settings_as_json_schema, types.String # TODO Convert to JsonStringType?
  field :settings_ui_schema, types.String # TODO Convert to JsonStringType?
  field :installation, TeamBotInstallationType # TODO What's this for?

  field :team_author do
    type -> { TeamType }
    description 'Team that published this bot'

    resolve -> (bot, _args, _ctx) {
      RecordLoader.for(Team).load(bot.team_author_id.to_i)
    }
  end
end
