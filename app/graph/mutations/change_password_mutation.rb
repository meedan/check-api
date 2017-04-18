ChangePasswordMutation = GraphQL::Relay::Mutation.define do
  name 'ChangePassword'

  input_field :password, !types.String
  input_field :password_confirmation, !types.String
  input_field :reset_password_token, !types.String

  return_field :success, types.Boolean

  resolve -> (inputs, _ctx) {
    user = User.reset_password_by_token(inputs)
    raise user.errors.to_a.to_sentence(locale: I18n.locale) if !user.errors.empty?
    { success: true }
  }
end
