VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'Version type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :item_type, types.String
  field :item_id, types.String
  field :event, types.String
  field :event_type, types.String
  field :object_after, types.String
  field :meta, types.String
  field :object_changes_json, types.String

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
end
