class UserDisconnectLoginAccountMutation < Mutations::BaseMutation
  graphql_name "UserDisconnectLoginAccount"

  argument :provider, GraphQL::Types::String, required: true
  argument :uid, GraphQL::Types::String, required: true

  field :success, GraphQL::Types::Boolean, null: true
  field :user, MeType, null: true

  def resolve(provider:, uid:)
    user = User.current
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.disconnect_login_account(provider, uid)
      { success: true, user: User.current }
    end
  end
end
