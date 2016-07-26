UserType = GraphQL::ObjectType.define do
  name 'User'
  description 'User type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('User')
  field :email, types.String
  field :provider, types.String
  field :uuid, types.String
  field :profile_image, types.String
  field :login, types.String
  field :name, types.String

  field :source do
    type SourceType
    resolve -> (user, _args, _ctx) do
      user.source
    end
  end

  connection :teams, -> { TeamType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.teams
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.projects
    }
  end
end
