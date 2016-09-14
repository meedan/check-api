QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :node, field: NodeIdentification.field

  field :root, RootLevelType do
    resolve -> (_obj, _args, _ctx) { RootLevel::STATIC }
  end

  field :about do
    type AboutType
    description 'Information about the application'
    resolve -> (_obj, _args, _ctx) do
      OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About', tos: CONFIG['terms_of_service'], privacy_policy: CONFIG['privacy_policy'] })
    end
  end

  field :me do
    type UserType
    description 'Information about the current user'
    resolve -> (_obj, _args, ctx) do
      ctx[:current_user]
    end
  end

  # Getters by ID

  [:source, :user, :team, :media, :project].each do |type|
    field type do
      type "#{type.to_s.camelize}Type".constantize
      description "Information about the #{type} with given id"
      argument :id, !types.ID
      resolve -> (_obj, args, ctx) do
        obj = type.to_s.camelize.constantize.find_if_can(args['id'], ctx[:current_user], ctx[:context_team])
        obj.current_user = ctx[:current_user]
        obj.context_team = ctx[:context_team]
        obj
      end
    end
  end
end
