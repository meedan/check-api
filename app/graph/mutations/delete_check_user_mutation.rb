DeleteCheckUserMutation = GraphQL::Relay::Mutation.define do
  name 'DeleteCheckUser'

  input_field :id, !types.String

  return_field :success, types.Boolean

  resolve -> (_root, inputs, ctx) {
    user = CheckGraphql.object_from_id(inputs[:id], ctx)
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      User.delete_check_user(user)
      { success: true }
    end
  }
end

