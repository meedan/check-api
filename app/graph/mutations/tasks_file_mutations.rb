module TasksFileMutations
  class AddFilesToTask < Mutation::Base
    graphql_name "AddFilesToTask"

    argument :id, ID, required: true

    field :task, TaskType, null: true

    def resolve(**inputs)
      task = GraphqlCrudOperations.object_from_id_if_can(
          inputs[:id],
          context[:ability]
        )
      files = [context[:file]].flatten.reject { |f| f.blank? }
      task.add_files(files) if task.is_a?(Task) && !files.empty?
      { task: task }
    end
  end

  class RemoveFilesFromTask < Mutation::Base
    graphql_name "RemoveFilesFromTask"

    argument :id, ID, required: true
    argument :filenames, [String], required: false

    field :task, TaskType, null: true

    def resolve(**inputs)
      task = GraphqlCrudOperations.object_from_id_if_can(
        inputs[:id],
        context[:ability]
      )
      filenames = inputs[:filenames]
      if task.is_a?(Task) && !filenames.empty?
        task.remove_files(filenames)
      end
      { task: task }
    end
  end
end
