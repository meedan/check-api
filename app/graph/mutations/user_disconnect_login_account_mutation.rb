class UserDisconnectLoginAccountMutation < Mutation::Base
  graphql_name "UserDisconnectLoginAccount"

  argument :provider, String, required: true
  argument :uid, String, required: true

  field :success, Boolean, null: true
  field :user, UserType, null: true

  def resolve(**inputs)
    user = User.current
    if user.nil?
      raise ActiveRecord::RecordNotFound
    else
      user.disconnect_login_account(inputs[:provider], inputs[:uid])
      { success: true, user: User.current }
    end
  end
end
