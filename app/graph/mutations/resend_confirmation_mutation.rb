ResendConfirmationMutation = GraphQL::Relay::Mutation.define do
  name 'ResendConfirmation'

  input_field :id, !types.Int

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.skip_check_ability = true
      user.send_confirmation_instructions
      { success: true }
    end
  }
end
