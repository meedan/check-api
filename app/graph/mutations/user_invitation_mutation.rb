class UserInvitationMutation < Mutation::Base
  graphql_name "UserInvitation"

  argument :invitation, String, required: false

  argument :members, JsonString, required: true

  field :errors, JsonString, null: true

  field :team, TeamType, null: true

  def resolve(**inputs)
    messages = User.send_user_invitation(inputs[:members], inputs[:invitation])
    { errors: messages, team: Team.current }
  end
end
