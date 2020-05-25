AccountSourceType = GraphqlCrudOperations.define_default_type do
  name 'AccountSource'
  description 'Links an Account to a Source.'

  interfaces [NodeIdentification.interface]

  field :account_id, types.Int, 'Account (id only)'
  field :source_id, types.Int, 'Source (id only)'

  field :account do
    type -> { AccountType }
    description 'Account'

    resolve -> (account_source, _args, _ctx) {
      account_source.account
    }
  end

  field :source do
    type -> { SourceType }
    description 'Source'

    resolve -> (account_source, _args, _ctx) {
      account_source.source
    }
  end
end
