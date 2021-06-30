module TasksFileMutations
  AddFilesToTask = GraphQL::Relay::Mutation.define do
    name 'AddFilesToTask'

    input_field :id, !types.ID

    return_field :task, TaskType

    resolve -> (_root, inputs, ctx) {
      task = GraphqlCrudOperations.object_from_id_if_can(inputs['id'], ctx['ability'])
      files = [ctx[:file]].flatten.reject{ |f| f.blank? }
      if task.is_a?(Task) && !files.empty?
        task.add_files(files)
      end
      { task: task }
    }
  end

  RemoveFilesFromTask = GraphQL::Relay::Mutation.define do
    name 'RemoveFilesFromTask'

    input_field :id, !types.ID
    input_field :filenames, types[types.String]

    return_field :task, TaskType

    resolve -> (_root, inputs, ctx) {
      task = GraphqlCrudOperations.object_from_id_if_can(inputs['id'], ctx['ability'])
      filenames = inputs['filenames']
      if task.is_a?(Task) && !filenames.empty?
        task.remove_files(filenames)
      end
      { task: task }
    }
  end
end
