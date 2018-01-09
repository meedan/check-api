UserType = GraphqlCrudOperations.define_default_type do
  name 'User'
  description 'User type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :email, types.String
  field :provider, types.String
  field :uuid, types.String
  field :profile_image, types.String
  field :login, types.String
  field :name, types.String
  field :current_team_id, types.Int
  field :permissions, types.String
  field :jsonsettings, types.String
  field :number_of_teams, types.Int

  field :source do
    type SourceType
    resolve -> (user, _args, _ctx) do
      RecordLoader.for(Source).load(user.source_id)
    end
  end

  field :current_team do
    type TeamType
    resolve -> (user, _args, _ctx) do
      user.current_team
    end
  end

  connection :teams, -> { TeamType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.teams
    }
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.team_users
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    argument :type, types.String

    resolve ->(user, args, _ctx) {
      type = args['type']
      type.blank? ? user.annotations : user.annotations(type)
    }
  end

  field :identity, JsonStringType do
    resolve -> (user, _args, _ctx) {
      user.identity
    }
  end
end
