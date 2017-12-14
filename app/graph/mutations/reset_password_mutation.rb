ResetPasswordMutation = GraphQL::Relay::Mutation.define do
  name 'ResetPassword'

  input_field :email, !types.String

  return_field :success, types.Boolean
  return_field :expiry, types.Int

  resolve -> (_root, inputs, _ctx) {
    user = User.where(email: inputs[:email]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound, I18n.t(:email_not_found, default: 'E-mail not found')
    else
      user.skip_check_ability = true
      user.send_reset_password_instructions
      { success: true, expiry: User.reset_password_within.to_i }
    end
  }
end
