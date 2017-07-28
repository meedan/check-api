TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', description: 'str', status: 'str' }) do
  field :first_response do
    type AnnotationType

    resolve -> (task, _args, _ctx) {
      obj = task.load
      obj.nil? ? nil : obj.responses.first
    }
  end

  field :first_response_value do
    type types.String

    resolve -> (task, _args, _ctx) {
      obj = task.load
      obj.nil? ? "" : obj.first_response
    }
  end

  field :jsonoptions do
    type types.String

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.jsonoptions unless obj.nil?
    }
  end
end
