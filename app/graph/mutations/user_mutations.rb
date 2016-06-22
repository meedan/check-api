module UserMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateUser'
    input_field :last_sign_in_ip, !types.String
    input_field :current_sign_in_ip, !types.String
    input_field :last_sign_in_at, !types.String
    input_field :current_sign_in_at, !types.String
    input_field :sign_in_count, !types.Int
    input_field :remember_created_at, !types.String
    input_field :reset_password_sent_at, !types.String
    input_field :reset_password_token, !types.String
    input_field :encrypted_password, !types.String
    input_field :email, !types.String
    input_field :token, !types.String
    input_field :provider, !types.String
    input_field :uuid, !types.String
    input_field :profile_image, !types.String
    input_field :login, !types.String
    input_field :name, !types.String

    return_field :user, UserType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      user = User.create(attr)

      { user: user }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateUser'
    input_field :last_sign_in_ip, types.String
    input_field :current_sign_in_ip, types.String
    input_field :last_sign_in_at, types.String
    input_field :current_sign_in_at, types.String
    input_field :sign_in_count, types.Int
    input_field :remember_created_at, types.String
    input_field :reset_password_sent_at, types.String
    input_field :reset_password_token, types.String
    input_field :encrypted_password, types.String
    input_field :email, types.String
    input_field :token, types.String
    input_field :provider, types.String
    input_field :uuid, types.String
    input_field :profile_image, types.String
    input_field :login, types.String
    input_field :name, types.String

    input_field :id, !types.ID

    return_field :user, UserType

    resolve -> (inputs, ctx) {
      user = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      user.update(attr)
      { user: user }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyUser"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      user = NodeIdentification.object_from_id((inputs[:id]), ctx)
      user.destroy
      { }
    }
  end
end
