module Types
  class AccountSourceType < DefaultObject
    description "AccountSource type"

    implements GraphQL::Types::Relay::NodeField

    field :account_id, Integer, null: true
    field :source_id, Integer, null: true

    field :source, SourceType, null: true

    def source
      object.source
    end

    field :account, AccountType, null: true

    def account
      object.account
    end
  end
end
