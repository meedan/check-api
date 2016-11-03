MediaType = GraphqlCrudOperations.define_default_type do
  name 'Media'
  description 'Media type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Media')
  field :updated_at, types.String
  field :url, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :dbid, types.Int
  field :domain, types.String
  field :pusher_channel, types.String

  field :account do
    type -> { AccountType }

    resolve -> (media, _args, _ctx) {
      media.account
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve -> (media, _args, _ctx) {
      media.projects
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    argument :context_id, types.Int

    resolve ->(media, args, ctx) {
      context = get_context(args, ctx)
      media.annotations(['comment', 'status', 'tag', 'flag'], context)
    }
  end

  field :annotations_count do
    type types.Int
    argument :context_id, types.Int

    resolve ->(media, args, ctx) {
      context = get_context(args, ctx)
      media.annotations_count(['comment', 'status', 'tag', 'flag'], context)
    }
  end

  connection :tags, -> { TagType.connection_type } do
    argument :context_id, types.Int

    resolve ->(media, args, ctx) {
      call_method_from_context(media, :tags, args, ctx)
    }
  end

  instance_exec :media, &GraphqlCrudOperations.field_verification_statuses
  instance_exec :jsondata, &GraphqlCrudOperations.field_with_context
  instance_exec :last_status, &GraphqlCrudOperations.field_with_context
  instance_exec :published, &GraphqlCrudOperations.field_with_context
  instance_exec :user, UserType, :user_in_context, &GraphqlCrudOperations.field_with_context
end

def get_context(args = {}, ctx = {})
  return ctx[:context_project] unless ctx[:context_project].nil?
  args['context_id'].nil? ? nil : Project.find_if_can(args['context_id'], ctx[:current_user], ctx[:context_team], ctx[:ability])
end

def call_method_from_context(media, method, args, ctx)
  context = get_context(args, ctx)
  media.send(method, context)
end
