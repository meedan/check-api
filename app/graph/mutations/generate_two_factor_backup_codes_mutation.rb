class GenerateTwoFactorBackupCodesMutation < Mutation::Base
  graphql_name "GenerateTwoFactorBackupCodes"

  argument :id, Integer, required: true

  field :success, Boolean, null: true
  field :codes, JsonString, null: true

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
