module UserMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateUser'
    input_field :email, !types.String
    input_field :profile_image, types.String
    input_field :login, !types.String
    input_field :name, !types.String

    return_field :user, UserType

    resolve -> (inputs, _ctx) {
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
    input_field :email, types.String
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
