UserDisconnectLoginAccountMutation = GraphQL::Relay::Mutation.define do
  name 'UserDisconnectLoginAccount'

  input_field :provider, !types.String

  return_field :success, types.Boolean

  return_field :user, UserType

  resolve -> (_root, inputs, _ctx) {
    user = User.current
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.disconnect_login_account(inputs[:provider])
      { success: true, user: User.current }
    end
  }
end