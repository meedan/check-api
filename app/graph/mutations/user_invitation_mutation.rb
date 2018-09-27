UserInvitationMutation = GraphQL::Relay::Mutation.define do
  name 'UserInvitation'

  input_field :invitation, types.String
  input_field :members, !JsonStringType

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    inputs[:members].each do |role, emails|
      emails.split(',').each do |email|
        User.invite!(:email => email, :name => "TODO", :invitation_role => role)
      end
    end
    { success: true }
  }
end
