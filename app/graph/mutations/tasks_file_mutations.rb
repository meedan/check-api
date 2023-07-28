module TasksFileMutations
  class AddFilesToTask < Mutations::BaseMutation
    argument :id, GraphQL::Types::ID, required: true

    field :task, TaskType, null: true

    def resolve(id:)
      task = GraphqlCrudOperations.object_from_id_if_can(
        id,
        context[:ability]
      )
      files = [context[:file]].flatten.reject { |f| f.blank? }
      task.add_files(files) if task.is_a?(Task) && !files.empty?
      { task: task }
    end
  end

  class RemoveFilesFromTask < Mutations::BaseMutation
    argument :id, GraphQL::Types::ID, required: true
    argument :filenames, [GraphQL::Types::String, null: true], required: false

    field :task, TaskType, null: true

    def resolve(id:, filenames: [])
      task = GraphqlCrudOperations.object_from_id_if_can(
        id,
        context[:ability]
      )
      if task.is_a?(Task) && !filenames.empty?
        task.remove_files(filenames)
      end
      { task: task }
    end
  end
end
