ApiKeyType = GraphQL::ObjectType.define do
  name 'ApiKey'
  description 'ApiKey type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ApiKey')
  field :application, types.String
  field :updated_at, types.String
  field :created_at, types.String
  field :expire_at, types.String
  field :access_token, types.String
  # End of fields
end
