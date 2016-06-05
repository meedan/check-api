QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root for this schema'

  field :about do
    type AboutType
    description 'Information about the application'
    resolve -> (obj, args, ctx) do
      OpenStruct.new({ name: Rails.application.class.parent_name, version: VERSION, id: 1, type: 'About' })
    end
  end

  # Add other fields here, one per model you want to expose (then add a type at app/graph/types)

  field :node, field: NodeIdentification.field
end
