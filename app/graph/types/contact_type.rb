# TODO Merge in Team
ContactType = GraphqlCrudOperations.define_default_type do
  name 'Contact'
  description 'Contact entries for a Team.'

  interfaces [NodeIdentification.interface]

  field :location, types.String, 'Geographical location'
  field :phone, types.String, 'Phone number'
  field :web, types.String, 'Web URL'
  field :team_id, types.Int, 'Team (id only)'
  field :permissions, types.String, 'CRUD permissions for current user'
  field :team do
    type -> { TeamType }
    description 'Team'

    resolve -> (contact, _args, _ctx) {
      contact.team
    }
  end
end
