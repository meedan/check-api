UserInvitationMutation = GraphQL::Relay::Mutation.define do
  name 'UserInvitation'

  input_field :invitation, types.String

  input_field :members, !Types::JsonString

  return_field :errors, Types::JsonString

  return_field :team, Types::TeamType

  resolve -> (_root, inputs, _ctx) {
    messages = User.send_user_invitation(inputs[:members], inputs[:invitation])
    { errors: messages, team: Team.current }
  }
end
