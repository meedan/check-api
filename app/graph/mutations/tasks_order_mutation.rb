TasksOrderMutation = GraphQL::Relay::Mutation.define do
  name 'TasksOrder'

  input_field :tasks, !JsonStringType

  return_field :success, types.Boolean

  return_field :errors, JsonStringType

  resolve -> (_root, inputs, _ctx) {
    errors = Task.order_tasks(inputs[:tasks])
    { success: true, errors: errors }
  }
end
