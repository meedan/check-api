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
end
