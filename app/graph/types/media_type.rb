MediaType = GraphQL::ObjectType.define do
  name 'Media'
  description 'Media type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Media')
  field :updated_at, types.String
  field :created_at, types.String
  field :data, types.String
  field :url, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :user_id, types.Int
    field :project do
    type -> { ProjectType }

    resolve -> (media, _args, _ctx) {
      media.project
    }
  end

  field :account do
    type -> { AccountType }

    resolve -> (media, _args, _ctx) {
      media.account
    }
  end

  field :user do
    type UserType

    resolve -> (media, _args, _ctx) {
      media.user
    }
  end
# End of fields
end
