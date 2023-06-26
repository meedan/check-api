class ResetPasswordMutation < Mutations::BaseMutation
  graphql_name 'ResetPassword'

  argument :email, GraphQL::Types::String, required: true

  field :success, GraphQL::Types::Boolean, null: true

  def resolve(**inputs)
    user = User.where(email: inputs[:email].downcase).last
    unless user.nil?
      user.skip_check_ability = true
      user.send_reset_password_instructions
    end
    { success: true }
  end
end
