class ResendConfirmationMutation < Mutations::BaseMutation
  graphql_name 'ResendConfirmation'

  argument :id, Integer, required: true

  field :success, Boolean, null: true

  def resolve(**inputs)
    user = User.where(id: inputs[:id]).last
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.skip_check_ability = true
      user.send_confirmation_instructions
      { success: true }
    end
  end
end
