class ResendConfirmationMutation < Mutations::BaseMutation
  graphql_name 'ResendConfirmation'

  argument :id, GraphQL::Types::Int, required: true

  field :success, GraphQL::Types::Boolean, null: true

  def resolve(id: nil)
    user = User.where(id: id).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.skip_check_ability = true
      user.send_confirmation_instructions
      { success: true }
    end
  end
end
