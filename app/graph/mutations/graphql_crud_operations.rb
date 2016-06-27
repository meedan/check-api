class GraphqlCrudOperations
  def self.create(type, inputs)
    attr = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId"
      memo
    end

    obj = type.camelize.constantize.create(attr)

    { type.to_sym => obj }
  end

  def self.update(type, inputs, ctx)
    obj = NodeIdentification.object_from_id((inputs[:id]), ctx)
    attr = inputs.keys.inject({}) do |memo, key|
      memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
      memo
    end

    obj.update(attr)
    { type.to_sym => obj }
  end

  def self.destroy(inputs, ctx)
    obj = NodeIdentification.object_from_id((inputs[:id]), ctx)
    obj.destroy
    { }
  end

  def self.define_create(type, create_fields) do
    self.define_create_or_update('create', type, fields)
  end

  def self.define_update(type, update_fields) do
    self.define_create_or_update('update', type, fields)
  end

  def self.define_create_or_update(action, type, fields)
    name "#{action.camelize}#{type.camelize}"
   
    fields.each do |field_name, field_type|
      input_field field_name, field_type
    end

    return_field type.to_sym, "#{type.camelize}Type".constantize

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.send(action, type, inputs, ctx)
    }
  end

  def self.define_destroy(type) do
    return GraphQL::Relay::Mutation.define do
      name "Destroy#{type.camelize}"

      input_field :id, !types.ID

      resolve -> (inputs, ctx) {
        GraphqlCrudOperations.destroy(inputs, ctx)
      }
  end

  def self.define_crud_operations(type, create_fields, update_fields = {})
    update_fields = create_fields if update_fields.empty?
    [
      GraphQL::Relay::Mutation.define_create(type, create_fields),
      GraphQL::Relay::Mutation.define_update(type, update_fields),
      GraphqlCrudOperations.define_destroy(type)
    ]
  end
end
