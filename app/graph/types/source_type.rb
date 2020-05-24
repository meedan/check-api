SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'A real-world entity that publishes media and makes claims.'

  interfaces [NodeIdentification.interface]

  field :image, types.String, 'Picture' # TODO Rename to 'picture'
  field :description, !types.String
  field :name, !types.String
  field :dbid, types.Int, 'Database id of this record'
  field :user_id, types.Int
  field :permissions, types.String, 'CRUD permissions for current user'
  field :pusher_channel, types.String, 'Channel for push notifications'
  field :lock_version, types.Int
  field :medias_count, types.Int
  field :accounts_count, types.Int

  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.accounts
    }
  end

  connection :account_sources, -> { AccountSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.account_sources
    }
  end

  # TODO Remove this
  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.project_sources
    }
  end

  # TODO Remove this
  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.projects
    }
  end

  connection :medias, -> { ProjectMediaType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.medias
    }
  end

  connection :collaborators, -> { UserType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.collaborators
    }
  end

  connection :tags, -> { TagType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.get_annotations('tag').map(&:load)
    }
  end

  # TODO What's this for?
  field :overridden do
    type JsonStringType

    resolve ->(source, _args, _ctx) {
      source.overridden
    }
  end

  instance_exec :source, &GraphqlCrudOperations.field_annotations

  instance_exec :source, &GraphqlCrudOperations.field_annotations_count

  instance_exec :source, &GraphqlCrudOperations.field_log

  instance_exec :source, &GraphqlCrudOperations.field_log_count
end
