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
      OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About' })
    end
  end

  # End Of Queries
end
