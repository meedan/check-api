ContactType = GraphqlCrudOperations.define_default_type do
  name 'Contact'
  description 'Contact type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Contact')
  field :updated_at, types.String
  field :created_at, types.String
  field :location, types.String
  field :phone, types.String
  field :web, types.String
  field :team_id, types.Int
  field :permissions, types.String
  field :team do
    type -> { TeamType }

    resolve -> (contact, _args, _ctx) {
      contact.team
    }
  end

# End of fields
end
