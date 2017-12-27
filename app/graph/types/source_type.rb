SourceType = GraphqlCrudOperations.define_default_type do
  name 'Source'
  description 'Source type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :user_id, types.Int
  field :permissions, types.String
  
  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.accounts
    }
  end

  connection :account_sources, -> { AccountSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.account_sources
    }
  end

end
