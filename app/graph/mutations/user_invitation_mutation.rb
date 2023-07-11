class UserInvitationMutation < Mutations::BaseMutation
  graphql_name "UserInvitation"

  argument :invitation, GraphQL::Types::String, required: false

  argument :members, JsonStringType, required: true

  field :errors, JsonStringType, null: true

  field :team, TeamType, null: true

  def resolve(**inputs)
    messages = User.send_user_invitation(inputs[:members], inputs[:invitation])
    { errors: messages, team: Team.current }
  end
end
