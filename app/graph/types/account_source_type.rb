AccountSourceType = GraphqlCrudOperations.define_default_type do
  name 'AccountSource'
  description 'Links an account to a source.'

  interfaces [NodeIdentification.interface]

  field :account_id, types.Int, 'Account database id'
  field :source_id, types.Int, 'Source database id'

  field :account, -> { AccountType }, 'Account' do
    resolve -> (account_source, _args, _ctx) {
      account_source.account
    }
  end

  field :source, -> { SourceType }, 'Source' do
    resolve -> (account_source, _args, _ctx) {
      account_source.source
    }
  end
end
