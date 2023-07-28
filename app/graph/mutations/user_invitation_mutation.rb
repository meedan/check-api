class UserInvitationMutation < Mutations::BaseMutation
  graphql_name "UserInvitation"

  argument :invitation, GraphQL::Types::String, required: false
  argument :members, JsonStringType, required: true

  field :errors, JsonStringType, null: true
  field :team, TeamType, null: true

  def resolve(invitation: nil, members: nil)
    messages = User.send_user_invitation(members, invitation)
    { errors: messages, team: Team.current }
  end
end
