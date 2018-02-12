ResendConfirmationMutation = GraphQL::Relay::Mutation.define do
  name 'ResendConfirmation'

  input_field :email, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(email: inputs[:email]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound, I18n.t(:email_not_found, default: 'E-mail not found')
    else
      user.skip_check_ability = true
      user.send_confirmation_instructions
      { success: true }
    end
  }
end
