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
  field :associated_graphql_id, types.String

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
