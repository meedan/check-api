SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'A real-world entity that publishes media and makes claims.'

  interfaces [NodeIdentification.interface]

  field :name, !types.String, 'Name'
  field :description, !types.String, 'Description'
  field :image, types.String, 'Picture' # TODO Rename to 'picture'
  field :user_id, types.Int, 'Creator of this item' # TODO Correct?
  field :lock_version, types.Int # TODO What's this?
  field :accounts_count, types.Int, 'Count of social profiles belonging to this source'

  connection :accounts, -> { AccountType.connection_type } do
    description 'List of social profiles belonging to this source'

    resolve ->(source, _args, _ctx) {
      source.accounts
    }
  end

  # TODO Do we need this?
  connection :account_sources, -> { AccountSourceType.connection_type } do
    description 'List of social profiles belonging to this source'

    resolve ->(source, _args, _ctx) {
      source.account_sources
    }
  end

  field :medias_count, types.Int, 'Count of items published by this source'

  connection :medias, -> { ProjectMediaType.connection_type } do
    description 'List of items published by this source'

    resolve ->(source, _args, _ctx) {
      source.medias
    }
  end

  connection :collaborators, -> { UserType.connection_type } do
    description 'TODO'

    resolve ->(source, _args, _ctx) {
      source.collaborators
    }
  end

  # TODO Review if we still need
  field :overridden do
    type JsonStringType

    resolve ->(source, _args, _ctx) {
      source.overridden
    }
  end

  instance_exec :source, &GraphqlCrudOperations.field_annotations

  field :dbid, types.Int, 'Database id of this record'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
  field :pusher_channel, types.String, 'Channel for push notifications'
end
