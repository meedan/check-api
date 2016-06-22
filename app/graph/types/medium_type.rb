MediumType = GraphQL::ObjectType.define do
  name 'Medium'
  description 'Medium type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Medium')
  field :updated_at, types.String
  field :created_at, types.String
  field :data, types.String
  field :url, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
    field :project do
    type -> { ProjectType }

    resolve -> (medium, args, ctx) {
      medium.project
    }
  end

  field :account do
    type -> { AccountType }

    resolve -> (medium, args, ctx) {
      medium.account
    }
  end

  field :user do
    type UserType

    resolve -> (medium, args, ctx) {
      medium.user
    }
  end
# End of fields
end
