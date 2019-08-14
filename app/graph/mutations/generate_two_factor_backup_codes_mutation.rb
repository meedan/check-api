GenerateTwoFactorBackupCodesMutation = GraphQL::Relay::Mutation.define do
  name 'GenerateTwoFactorBackupCodes'

  input_field :id, !types.Int

  return_field :success, types.Boolean
  return_field :codes, JsonStringType

  resolve -> (_root, inputs, _ctx) {
    user = User.where(id: inputs[:id]).last
    if user.nil? || User.current.id != inputs[:id]
      raise ActiveRecord::RecordNotFound
    else
      codes = user.generate_otp_codes
      { success: true , codes: codes}
    end
  }
end
