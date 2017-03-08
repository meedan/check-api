TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', description: 'str', jsonoptions: 'str', status: 'str' }) do
  field :first_response do
    type AnnotationType

    resolve -> (task, _args, _ctx) {
      obj = task.load
      obj.nil? ? nil : obj.responses.first
    }
  end
end
