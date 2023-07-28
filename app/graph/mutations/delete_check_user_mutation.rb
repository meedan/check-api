class DeleteCheckUserMutation < Mutations::BaseMutation
  graphql_name 'DeleteCheckUser'

  argument :id, GraphQL::Types::Int, required: true

  field :success, GraphQL::Types::Boolean, null: true

  def resolve(id:)
    user = User.where(id: id).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      ability = Ability.new(user)
      raise I18n.t('permission_error', "Sorry, you are not allowed to perform this operation") if ability.cannot?(:destroy, user)
      User.delete_check_user(user)
      { success: true }
    end
  end
end
