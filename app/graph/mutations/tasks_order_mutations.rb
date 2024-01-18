module TasksOrderMutations
  class BaseMoveMutation < Mutations::BaseMutation
    argument :id, GraphQL::Types::ID, required: true

    def move(object, id, context, object_field, parent_field)
      object = GraphqlCrudOperations.object_from_id_if_can(
        id,
        context[:ability]
      )
      parent = object.send(parent_field)
      yield(object) # any changes that must be made on object
      { object_field => object, parent_field => parent }
    end
  end

  class MoveTeamTaskUp < BaseMoveMutation
    field :team_task, TeamTaskType, null: true, camelize: false
    field :team, TeamType, null: true

    def resolve(id:)
      move(object, id, context, :team_task, :team) { |obj| obj.move_up }
    end
  end

  class MoveTeamTaskDown < BaseMoveMutation
    field :team_task, TeamTaskType, null: true, camelize: false
    field :team, TeamType, null: true

    def resolve(id:)
      move(object, id, context, :team_task, :team) { |obj| obj.move_down }
    end
  end
end
