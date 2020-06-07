# TODO Merge in Team
ContactType = GraphqlCrudOperations.define_default_type do
  name 'Contact'
  description 'Contact entries for a team.'

  interfaces [NodeIdentification.interface]

  field :location, types.String, 'Geographical location'
  field :phone, types.String, 'Phone number'
  field :web, types.String, 'Web URL'
  field :team_id, types.Int, 'Team database id'
  field :permissions, types.String, 'CRUD permissions for current user'
  field :team, -> { TeamType }, 'Team' do
    resolve -> (contact, _args, _ctx) {
      contact.team
    }
  end
end
