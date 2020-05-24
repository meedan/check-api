VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'An entry in the version-control log.'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int, 'Database id of this record'
  field :item_type, types.String
  field :item_id, types.String
  field :event, types.String
  field :event_type, types.String
  field :object_after, types.String # Do we need both this and 'object_changes'?
  field :meta, types.String
  field :object_changes_json, types.String # TODO Convert to JsonStringType and rename to 'object_changes'
  field :associated_graphql_id, types.String
  field :smooch_user_slack_channel_url, types.String

  field :user do
    type -> { UserType }

    resolve ->(version, _args, _ctx) {
      version.user
    }
  end

  field :annotation do
    type -> { AnnotationType }

    resolve ->(version, _args, _ctx) {
      version.annotation
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(version, _args, _ctx) {
      version.projects
    }
  end

  connection :teams, -> { TeamType.connection_type } do
    resolve ->(version, _args, _ctx) {
      version.teams
    }
  end

  field :task do
    type -> { TaskType }

    resolve ->(version, _args, _ctx) {
      version.task
    }
  end

  field :tag do
    type -> { TagType }

    resolve ->(version, _args, _ctx) {
      Tag.find(version.annotation.id) unless version.annotation.nil?
    }
  end
end
