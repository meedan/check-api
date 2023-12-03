class UserInvitationMutation < Mutations::BaseMutation
  graphql_name "UserInvitation"

  argument :invitation, GraphQL::Types::String, required: false
  argument :members, JsonStringType, required: true

  field :errors, JsonStringType, null: true
  field :team, TeamType, null: true

  def resolve(invitation: nil, members:)
    team = Team.find_if_can(Team.current.id, context[:ability])
    messages = User.send_user_invitation(members, invitation)
    { errors: messages, team: team }
  end
end
