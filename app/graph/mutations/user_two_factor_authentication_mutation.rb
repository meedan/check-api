class UserTwoFactorAuthenticationMutation < Mutations::BaseMutation
  graphql_name "UserTwoFactorAuthentication"

  argument :id, GraphQL::Types::Int, required: true
  argument :password, GraphQL::Types::String, required: true
  argument :qrcode, GraphQL::Types::String, required: false
  argument :otp_required, GraphQL::Types::Boolean, required: false, camelize: false

  field :success, GraphQL::Types::Boolean, null: true
  field :user, UserType, null: true

  def resolve(id: nil, password: nil, qrcode: nil, otp_required: nil)
    user = User.where(id: id).last
    if user.nil? || User.current.id != id
      raise ActiveRecord::RecordNotFound
    else
      options = {
        otp_required: otp_required,
        password: password,
        qrcode: qrcode
      }
      user.two_factor = (options)
      { success: true, user: user.reload }
    end
  end
end
