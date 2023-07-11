class GenerateTwoFactorBackupCodesMutation < Mutations::BaseMutation
  graphql_name "GenerateTwoFactorBackupCodes"

  argument :id, GraphQL::Types::Int, required: true

  field :success, GraphQL::Types::Boolean, null: true
  field :codes, JsonStringType, null: true

  def resolve(**inputs)
    user = User.where(id: inputs[:id]).last
    if user.nil? || User.current.id != inputs[:id]
      raise ActiveRecord::RecordNotFound
    else
      codes = user.generate_otp_codes
      { success: true, codes: codes }
    end
  end
end
