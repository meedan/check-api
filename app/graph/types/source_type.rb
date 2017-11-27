SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'Source type'

  interfaces [NodeIdentification.interface]

  field :image, types.String
  field :description, !types.String
  field :dbid, types.Int
  field :user_id, types.Int
  field :permissions, types.String
  field :pusher_channel, types.String

  field :name do
    type !types.String

    resolve -> (source, _args, _ctx) {
      source.get_name
    }
  end

  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.accounts
    }
  end

  field :team_source do
    type -> { TeamSourceType }

    resolve -> (source, _args, _ctx) {
      source.get_team_source
    }
  end

  connection :account_sources, -> { AccountSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.account_sources
    }
  end

  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.project_sources
    }
  end

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
      source.get_annotations('tag')
    }
  end

  instance_exec :source, &GraphqlCrudOperations.field_annotations

  instance_exec :source, &GraphqlCrudOperations.field_annotations_count

  instance_exec :source, &GraphqlCrudOperations.field_log

  instance_exec :source, &GraphqlCrudOperations.field_log_count

  instance_exec :source, &GraphqlCrudOperations.field_verification_statuses

end
