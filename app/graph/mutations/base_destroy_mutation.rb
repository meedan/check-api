# Abstract class for destroy mutations
class BaseDestroyMutation < GraphQL::Schema::RelayClassicMutation
  argument :id, ID, required: true

  field :deletedId, ID, null: true

  def define_destroy_behavior(subclass, mutation_target, parents)
    subclass.graphql_name "Destroy#{mutation_target.to_s.camelize}"

    type_class = "#{mutation_target.to_s.camelize}Type".constantize
    subclass.field mutation_target, type_class, null: true
    subclass.field "#{type_class}Edge", type_class.edge_type, null: true

    parents.each do |parent_field|
      subclass.field parent_field.to_sym, "#{parent_field.camelize}Type", null: true
    end

    subclass.class_eval <<~METHOD
      def resolve(**inputs)
        GraphqlCrudOperations.destroy(inputs, context, #{parents})
      end
    METHOD
  end
end

    # HANDLE IN CLASS
    # input_field(:keep_completed_tasks, types.Boolean) if type == "team_task"

    # HANDLE IN CLASS
    # if type == "relationship"
    #   input_field(:add_to_project_id, types.Int)
    #   input_field(:archive_target, types.Int)
    # end

    # HANDLE IN CLASS
    # input_field(:items_destination_project_id, types.Int) if type == "project"
