UserDisconnectLoginAccountMutation = GraphQL::Relay::Mutation.define do
  name 'UserDisconnectLoginAccount'

  input_field :id, !types.Int

  input_field :provider, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.disconnect_login_account(inputs[:provider])
      { success: true }
    end
  }
end