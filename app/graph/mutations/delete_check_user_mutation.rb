DeleteCheckUserMutation = GraphQL::Relay::Mutation.define do
  name 'DeleteCheckUser'

  input_field :id, !types.Int

  return_field :success, types.Boolean

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      ability = Ability.new(user)
      raise I18n.t('permission_error', "Sorry, you are not allowed to perform this operation") if ability.cannot?(:destroy, user)
      User.delete_check_user(user)
      { success: true }
    end
  }
end
