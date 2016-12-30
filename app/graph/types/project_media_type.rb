ProjectMediaType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMedia'
  description 'ProjectMedia type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ProjectMedia')
  field :updated_at, types.String
  field :created_at, types.String
  field :media_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
  field :dbid, types.Int
  field :permissions, types.String

  field :url do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      project_media.media.url
    }
  end

  field :quote do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      project_media.media.quote
    }
  end

  field :domain do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      project_media.media.domain
    }
  end

  field :pusher_channel do
    type types.String

    resolve -> (project_media, _args, _ctx) {
      project_media.media.pusher_channel
    }
  end

  field :account do
    type -> { AccountType }

    resolve -> (project_media, _args, _ctx) {
      project_media.media.account
    }
  end

  field :project do
    type -> { ProjectType }

    resolve -> (project_media, _args, _ctx) {
      project_media.project
    }
  end

  field :media do
    type -> { MediaType }

    resolve -> (project_media, _args, _ctx) {
      project_media.media
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (project_media, _args, _ctx) {
      project_media.user
    }
  end

  field :team do
    type -> { TeamType }

    resolve ->(project_media, _args, _ctx) {
      project_media.project.team
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      project_media.cached_annotations(annotation_types)
    }
  end

  field :annotations_count do
    type types.Int

    resolve ->(project_media, _args, _ctx) {
      project_media.cached_annotations(annotation_types).size
    }
  end

  connection :tags, -> { TagType.connection_type } do
    resolve ->(project_media, _args, _ctx) {
      call_method_from_context(project_media, :tags)
    }
  end

  instance_exec :media, &GraphqlCrudOperations.field_verification_statuses
  instance_exec :jsondata, &GraphqlCrudOperations.field_with_context
  instance_exec :last_status, &GraphqlCrudOperations.field_with_context
  instance_exec :published, &GraphqlCrudOperations.field_with_context

# End of fields
end

def annotation_types
  ['comment', 'status', 'tag', 'flag']
end

def call_method_from_context(project_media, method)
  project_media.send(method)
end
