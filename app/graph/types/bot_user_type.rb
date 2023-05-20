module Types
  class BotUserType < DefaultObject
    description "Bot User type"

    implements GraphQL::Types::Relay::NodeField

    field :avatar, String, null: true
    field :name, String, null: true
    field :get_description, String, null: true
    field :get_version, String, null: true
    field :get_source_code_url, String, null: true
    field :get_role, String, null: true
    field :identifier, String, null: true
    field :login, String, null: true
    field :dbid, Integer, null: true
    field :installed, Boolean, null: true
    field :installations_count, Integer, null: true
    field :settings_ui_schema, String, null: true
    field :installation, TeamBotInstallationType, null: true
    field :default, Boolean, null: true

    field :settings_as_json_schema, String, null: true do
      argument :team_slug, String, required: false # Some settings options are team-specific
    end

    def settings_as_json_schema(**args)
      object.settings_as_json_schema(false, args[:team_slug])
    end

    field :team_author, TeamType, null: true

    def team_author
      RecordLoader.for(Team).load(object.team_author_id.to_i)
    end
  end
end
