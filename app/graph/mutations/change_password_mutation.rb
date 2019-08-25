ChangePasswordMutation = GraphQL::Relay::Mutation.define do
  name 'ChangePassword'

  input_field :password, !types.String
  input_field :password_confirmation, !types.String
  input_field :reset_password_token, types.String
  input_field :current_password, types.String
  input_field :id, types.Int

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.reset_change_password(inputs)
    raise user.errors.to_a.to_sentence(locale: I18n.locale) if !user.errors.empty?
    { success: true }
  }
end
