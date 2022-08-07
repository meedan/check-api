FeedType = GraphqlCrudOperations.define_default_type do
  name 'Feed'
  description 'Feed type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :name, types.String
end
