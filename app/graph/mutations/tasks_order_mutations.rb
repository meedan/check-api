module TasksOrderMutations
  class BaseMoveMutation < Mutation::Base
    argument :id, ID, required: true

    def move(object, inputs, context, object_field, parent_field)
      object = GraphqlCrudOperations.object_from_id_if_can(
        inputs[:id],
        context[:ability]
      )
      parent = object.send(parent_field)
      yield(object) # any changes that must be made on object
      pp object.order
      { object_field => object, parent_field => parent }
    end
  end

  class MoveTaskUp < BaseMoveMutation
    field :task, TaskType, null: true
    field :project_media, ProjectMediaType, null: true, camelize: false

    def resolve(**inputs)
      move(object, inputs, context, :task, :project_media) { |obj| obj.move_up }
    end
  end

  class MoveTaskDown < BaseMoveMutation
    field :task, TaskType, null: true
    field :project_media, ProjectMediaType, null: true, camelize: false

    def resolve(**inputs)
      move(object, inputs, context, :task, :project_media) { |obj| obj.move_down }
    end
  end

  class MoveTeamTaskUp < BaseMoveMutation
    field :team_task, TeamTaskType, null: true, camelize: false
    field :team, TeamType, null: true

    def resolve(**inputs)
      move(object, inputs, context, :team_task, :task) { |obj| obj.move_up }
    end
  end

  class MoveTeamTaskDown < BaseMoveMutation
    field :team_task, TeamTaskType, null: true, camelize: false
    field :team, TeamType, null: true

    def resolve(**inputs)
      move(object, inputs, context, :team_task, :task) { |obj| obj.move_down }
    end
  end
end
