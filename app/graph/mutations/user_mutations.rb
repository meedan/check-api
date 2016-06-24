module UserMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateUser'
    input_field :email, !types.String
    input_field :profile_image, types.String
    input_field :login, !types.String
    input_field :name, !types.String

    return_field :user, UserType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('user', inputs)
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
      GraphqlCrudOperations.update('user', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyUser"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
