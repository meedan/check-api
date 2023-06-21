class UserTwoFactorAuthenticationMutation < Mutation::Base
  graphql_name "UserTwoFactorAuthentication"

  argument :id, Integer, required: true
  argument :password, String, required: true
  argument :qrcode, String, required: false
  argument :otp_required, Boolean, required: false

  field :success, Boolean, null: true
  field :user, UserType, null: true

  def resolve(**inputs)
    user = User.where(id: inputs[:id]).last
    if user.nil? || User.current.id != inputs[:id]
      raise ActiveRecord::RecordNotFound
    else
      options = {
        otp_required: inputs[:otp_required],
        password: inputs[:password],
        qrcode: inputs[:qrcode]
      }
      user.two_factor = (options)
      { success: true, user: user.reload }
    end
  end
end
