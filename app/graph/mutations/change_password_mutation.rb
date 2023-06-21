class ChangePasswordMutation < Mutations::BaseMutation
  graphql_name 'ChangePassword'

  argument :password, String, required: true
  argument :password_confirmation, String, required: true
  argument :reset_password_token, String, required: false
  argument :current_password, String, required: false
  argument :id, Integer, required: false

  field :success, Boolean, null: true

  def resolve(**inputs)
    user = User.reset_change_password(inputs)
    raise user.errors.to_a.to_sentence(locale: I18n.locale) if !user.errors.empty?
    { success: true }
  end
end
