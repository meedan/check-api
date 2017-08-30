SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'Source type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Source')
  field :image, types.String
  field :description, !types.String
  field :name, !types.String
  field :dbid, types.Int
  field :user_id, types.Int
  field :permissions, types.String
  field :pusher_channel, types.String

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

  connection :annotations, -> { AnnotationType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.annotations
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

  connection :comments, -> { CommentType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.comments
    }
  end

  connection :tags, -> { TagType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.tags
    }
  end

  instance_exec :source, &GraphqlCrudOperations.field_log

  instance_exec :source, &GraphqlCrudOperations.field_log_count

  instance_exec :source, &GraphqlCrudOperations.field_verification_statuses
end
