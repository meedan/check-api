SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'Source type'

  interfaces [NodeIdentification.interface]

  field :image, types.String
  field :description, !types.String
  field :name, !types.String
  field :dbid, types.Int
  field :user_id, types.Int
  field :permissions, types.String
  field :pusher_channel, types.String
  field :lock_version, types.Int
  field :medias_count, types.Int
  field :accounts_count, types.Int
  field :overridden, JsonStringType
  field :archived, types.Int

  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(source, _args, _ctx) { source.accounts }
  end

  connection :account_sources, -> { AccountSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.account_sources.order(id: :asc)
    }
  end

  connection :medias, -> { ProjectMediaType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.medias
    }
  end

  field :medias_count, types.Int do
    resolve -> (source, _args, _ctx) {
      source.medias_count
    }
  end

  connection :collaborators, -> { UserType.connection_type } do
    resolve ->(source, _args, _ctx) { source.collaborators }
  end

  instance_exec :source, &GraphqlCrudOperations.field_annotations

  instance_exec :source, &GraphqlCrudOperations.field_annotations_count

  instance_exec :source, &GraphqlCrudOperations.field_tasks
end
