module TasksOrderMutations
  class Generator
    def self.define_move_mutation(object_name, parent_name, direction)
      GraphQL::Relay::Mutation.define do
        name "Move#{object_name.capitalize}#{direction.capitalize}"

        input_field :id, !types.ID

        return_field object_name, "#{object_name.to_s.camelize}Type".constantize
        return_field parent_name, "#{parent_name.to_s.camelize}Type".constantize

        resolve -> (_root, inputs, ctx) {
          object = GraphqlCrudOperations.object_from_id_if_can(inputs['id'], ctx['ability'])
          parent = object.send(parent_name)
          object.send("move_#{direction}")
          { object_name => object, parent_name => parent }
        }
      end
    end
  end

  MoveTaskUp = Generator.define_move_mutation(:task, :project_media, :up)
  MoveTaskDown = Generator.define_move_mutation(:task, :project_media, :down)
  MoveTeamTaskUp = Generator.define_move_mutation(:team_task, :team, :up)
  MoveTeamTaskDown = Generator.define_move_mutation(:team_task, :team, :down)
end
