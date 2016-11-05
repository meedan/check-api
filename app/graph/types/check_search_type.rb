CheckSearchType = GraphqlCrudOperations.define_default_type do
  name 'CheckSearch'
  description 'CheckSearch type'

  interfaces [NodeIdentification.interface]

  field :number_of_results, types.Int
  
  connection :medias, MediaType.connection_type
end
