CheckSearchType = GraphqlCrudOperations.define_default_type do
  name 'CheckSearch'
  description 'CheckSearch type'

  interfaces [NodeIdentification.interface]

  connection :medias, -> { CheckSearchType.connection_type } do
    resolve ->(check_search, _args, _ctx) {
      check_search.medias
    }
  end

end
