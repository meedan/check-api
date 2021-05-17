ResetPasswordMutation = GraphQL::Relay::Mutation.define do
  name 'ResetPassword'

  input_field :email, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(email: inputs[:email]).last
    unless user.nil?
      user.skip_check_ability = true
      user.send_reset_password_instructions
    end
    { success: true }
  }
end
