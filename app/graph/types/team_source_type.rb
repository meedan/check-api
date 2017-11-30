TeamSourceType = GraphqlCrudOperations.define_default_type do
  name 'TeamSource'
  description 'TeamSource type'

  interfaces [NodeIdentification.interface]

  field :image, types.String
  field :name, !types.String
  field :description, !types.String
  field :dbid, types.Int
  field :user_id, types.Int
  field :permissions, types.String
  field :team_id, types.Int
  field :source_id, types.Int
  field :pusher_channel, types.String

  field :project_id do
    type types.Int

    resolve -> (team_source, _args, _ctx) {
      team_source.projects
    }
  end

  field :source do
    type -> { SourceType }

    resolve -> (team_source, _args, _ctx) {
      team_source.source
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (team_source, _args, _ctx) {
      team_source.team
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (team_source, _args, _ctx) {
      team_source.user
    }
  end

  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.source.accounts
    }
  end

  connection :account_sources, -> { AccountSourceType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.source.account_sources
    }
  end

  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.source.get_project_sources
    }
  end

  # connection :projects, -> { ProjectType.connection_type } do
  #   resolve ->(team_source, _args, _ctx) {
  #     team_source.projects
  #   }
  # end

  connection :medias, -> { ProjectMediaType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.medias
    }
  end

  connection :collaborators, -> { UserType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.collaborators
    }
  end

  connection :tags, -> { TagType.connection_type } do
    resolve ->(team_source, _args, _ctx) {
      team_source.get_annotations('tag')
    }
  end

  instance_exec :get_annotations, &GraphqlCrudOperations.field_annotations

  instance_exec :get_annotations, &GraphqlCrudOperations.field_annotations_count

  instance_exec :get_annotations, &GraphqlCrudOperations.field_log

  instance_exec :get_annotations, &GraphqlCrudOperations.field_log_count

  instance_exec :get_annotations, &GraphqlCrudOperations.field_verification_statuses

  instance_exec :team_source, &GraphqlCrudOperations.field_published

# End of fields
end
