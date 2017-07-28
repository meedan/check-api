AccountSourceType = GraphqlCrudOperations.define_default_type do
  name 'AccountSource'
  description 'AccountSource type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('AccountSource')
  field :account_id, types.Int
  field :source_id, types.Int
  field :permissions, types.String

  field :source do
    type -> { SourceType }

    resolve -> (account_source, _args, _ctx) {
      account_source.source
    }
  end

  field :account do
    type -> { AccountType }

    resolve -> (account_source, _args, _ctx) {
      account_source.account
    }
  end

# End of fields
end
