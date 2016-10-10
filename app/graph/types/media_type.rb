MediaType = GraphQL::ObjectType.define do
  name 'Media'
  description 'Media type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Media')
  field :updated_at, types.String
  field :url, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
  field :dbid, types.Int
  field :annotations_count, types.Int
  field :domain, types.String
  field :permissions, types.String

  field :published do
    type types.String

    resolve -> (media, _args, _ctx) {
      media.published
    }
  end

  field :jsondata do
    type types.String
    argument :context_id, types.Int

    resolve -> (media, _args, _ctx) {
      context = get_context(args, ctx)
      media.jsondata(context)
    }
  end

  field :account do
    type -> { AccountType }

    resolve -> (media, _args, _ctx) {
      media.account
    }
  end

  field :user do
    type UserType

    resolve -> (media, _args, _ctx) {
      media.user
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
      media.annotations(nil, context)
    }
  end

  connection :tags, -> { TagType.connection_type } do
    argument :context_id, types.Int

    resolve ->(media, args, ctx) {
      context = get_context(args, ctx)
      media.tags(context)
    }
  end

  field :last_status do
    type types.String

    argument :context_id, types.Int

    resolve ->(media, args, ctx) {
      context = get_context(args, ctx)
      media.last_status(context)
    }
  end
end

def get_context(args = {}, ctx = {})
  args['context_id'].nil? ? nil : Project.find_if_can(args['context_id'], ctx[:current_user], ctx[:context_team])
end
