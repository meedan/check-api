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
      OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About', tos: CONFIG['terms_of_service'] })
    end
  end

  field :me do
    type UserType
    description 'Information about the current user'
    resolve -> (_obj, _args, ctx) do
      ctx[:current_user]
    end
  end

  field :source do
    type SourceType
    description 'Information about the source with given id'
    argument :id, !types.ID
    resolve -> (_obj, args, _ctx) do
      Source.find(args['id'])
    end
  end

  # End Of Queries
end
