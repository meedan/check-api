UserInvitationMutation = GraphQL::Relay::Mutation.define do
  name 'UserInvitation'

  input_field :invitation, types.String
  input_field :members, !JsonStringType

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    messages = User.send_user_invitation(inputs[:members], inputs[:invitation])
    { success: true, messages: messages }
  }
end
