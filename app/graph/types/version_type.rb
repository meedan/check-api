VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'An entry in the version-control log.'

  interfaces [NodeIdentification.interface]

  field :item_type, types.String, 'Database type of item' # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
  field :item_id, types.String, 'Database id of item'
  field :event, types.String, 'TODO'
  field :event_type, types.String, 'TODO'
  field :object_after, types.String # Do we need both this and 'object_changes'?
  field :meta, types.String, 'TODO'
  field :object_changes_json, types.String, 'TODO' # TODO Convert to JsonStringType and rename to 'item_diff'
  field :associated_graphql_id, types.String, 'TODO'
  field :smooch_user_slack_channel_url, types.String, 'TODO'

  field :user, -> { UserType }, 'Log entry creator' do
    resolve ->(version, _args, _ctx) {
      version.user
    }
  end

  field :annotation, -> { AnnotationType }, 'Annotation associated with this log entry' do
    resolve ->(version, _args, _ctx) {
      version.annotation
    }
  end

  connection :projects, -> { ProjectType.connection_type }, 'Projects associated with this log entry' do
    resolve ->(version, _args, _ctx) {
      version.projects
    }
  end

  connection :teams, -> { TeamType.connection_type }, 'Teams associated with this log entry' do
    resolve ->(version, _args, _ctx) {
      version.teams
    }
  end

  # TODO Don't we already have annotation above?
  field :task do
    type -> { TaskType }
    description 'TODO'

    resolve ->(version, _args, _ctx) {
      version.task
    }
  end

  # TODO Don't we already have annotation above?
  field :tag do
    type -> { TagType }
    description 'TODO'

    resolve ->(version, _args, _ctx) {
      Tag.find(version.annotation.id) unless version.annotation.nil?
    }
  end

  field :dbid, types.Int, 'Database id of this record'
end
