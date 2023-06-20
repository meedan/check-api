class BotUserType < DefaultObject
  description "Bot User type"

  implements NodeIdentification.interface

  field :avatar, String, null: true
  field :name, String, null: true
  field :get_description, String, null: true

  def get_description
    object.get_description
  end

  field :get_version, String, null: true

  def get_version
    object.get_version
  end

  field :get_source_code_url, String, null: true

  def get_source_code_url
    object.get_source_code_url
  end

  field :get_role, String, null: true

  def get_role
    object.get_role
  end

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
