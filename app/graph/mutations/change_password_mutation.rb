class ChangePasswordMutation < Mutations::BaseMutation
  graphql_name 'ChangePassword'

  argument :password, GraphQL::Types::String, required: true
  argument :password_confirmation, GraphQL::Types::String, required: true, camelize: false
  argument :reset_password_token, GraphQL::Types::String, required: false, camelize: false
  argument :current_password, GraphQL::Types::String, required: false, camelize: false
  argument :id, GraphQL::Types::Int, required: false

  field :success, GraphQL::Types::Boolean, null: true

  def resolve(**inputs)
    user = User.reset_change_password(inputs)
    raise user.errors.to_a.to_sentence(locale: I18n.locale) if !user.errors.empty?
    { success: true }
  end
end
