class UserTwoFactorAuthenticationMutation < Mutations::BaseMutation
  graphql_name "UserTwoFactorAuthentication"

  argument :id, GraphQL::Types::Int, required: true
  argument :password, GraphQL::Types::String, required: true
  argument :qrcode, GraphQL::Types::String, required: false
  argument :otp_required, GraphQL::Types::Boolean, required: false

  field :success, GraphQL::Types::Boolean, null: true
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
