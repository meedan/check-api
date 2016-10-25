SearchResultType = GraphqlCrudOperations.define_default_type do
  name 'SearchResult'
  description 'SearchResult type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Media')
  field :updated_at, types.String
  field :url, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
  field :dbid, types.Int

end
