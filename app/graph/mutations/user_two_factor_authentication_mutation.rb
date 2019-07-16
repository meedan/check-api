UserTwoFactorAuthenticationMutation = GraphQL::Relay::Mutation.define do
  name 'UserTwoFactorAuthentication'

  input_field :id, !types.Int
  input_field :password, !types.String
  input_field :qrcode, types.String
  input_field :opt_required, types.Boolean

  return_field :success, types.Boolean
  return_field :user, UserType

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.two_factor=(inputs)
      { success: true , user: User.current}
    end
  }
end
