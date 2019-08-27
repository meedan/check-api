UserTwoFactorAuthenticationMutation = GraphQL::Relay::Mutation.define do
  name 'UserTwoFactorAuthentication'

  input_field :id, !types.Int
  input_field :password, !types.String
  input_field :qrcode, types.String
  input_field :otp_required, types.Boolean

  return_field :success, types.Boolean
  return_field :user, UserType

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil? || User.current.id != inputs[:id]
      raise ActiveRecord::RecordNotFound
    else
      options = { otp_required: inputs[:otp_required], password: inputs[:password], qrcode: inputs[:qrcode]}
      user.two_factor=(options)
      { success: true , user: user.reload }
    end
  }
end
