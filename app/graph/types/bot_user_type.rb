class BotUserType < DefaultObject
  description "Bot User type"

  implements GraphQL::Types::Relay::Node

  field :avatar, GraphQL::Types::String, null: true
  field :name, GraphQL::Types::String, null: true
  field :get_description, GraphQL::Types::String, null: true

  def get_description
    object.get_description
  end

  field :get_version, GraphQL::Types::String, null: true

  def get_version
    object.get_version
  end

  field :get_source_code_url, GraphQL::Types::String, null: true

  def get_source_code_url
    object.get_source_code_url
  end

  field :get_role, GraphQL::Types::String, null: true

  def get_role
    object.get_role
  end

  field :identifier, GraphQL::Types::String, null: true
  field :login, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :installed, GraphQL::Types::Boolean, null: true
  field :installations_count, GraphQL::Types::Int, null: true
  field :settings_ui_schema, GraphQL::Types::String, null: true
  field :installation, TeamBotInstallationType, null: true
  field :default, GraphQL::Types::Boolean, null: true

  field :settings_as_json_schema, GraphQL::Types::String, null: true do
    argument :team_slug, GraphQL::Types::String, required: false, camelize: false # Some settings options are team-specific
  end

  def settings_as_json_schema(team_slug: nil)
    object.settings_as_json_schema(false, team_slug)
  end

  field :team_author, PublicTeamType, null: true

  def team_author
    RecordLoader.for(Team).load(object.team_author_id.to_i)
  end

  field :events, GraphQL::Types::String, null: true
  field :request_url, GraphQL::Types::String, null: true
  field :headers, GraphQL::Types::String, null: true

  def events
    object.get_events.to_json
  end

  def request_url
    object.get_request_url
  end

  def headers
    object.get_headers.to_json
  end
end
