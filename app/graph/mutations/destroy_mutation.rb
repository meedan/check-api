class DestroyMutation < BaseMutation
  class << self
    def inherited(subclass)
      define_behavior(subclass, subclass.module_parent::MUTATION_TARGET, subclass.module_parent::PARENTS)
    end

    def define_behavior(subclass, mutation_target, parents)
      subclass.graphql_name "Destroy#{mutation_target.to_s.camelize}"

      subclass.argument :id, GraphQL::Types::ID, required: true
      subclass.field :deletedId, GraphQL::Types::ID, null: true

      type_class = "#{mutation_target.to_s.camelize}Type".constantize
      subclass.field mutation_target, type_class, camelize: false, null: true
      subclass.field "#{type_class}Edge", type_class.edge_type, null: true

      parents.each do |parent_field|
        subclass.field parent_field.to_sym, "#{parent_field.camelize}Type", null: true
      end

      subclass.define_method :resolve do |**inputs|
        ::GraphqlCrudOperations.destroy(inputs, context, parents)
      end

      # type = MUTATION_TARGET
      # parents = PARENTS

      # HANDLE IN CLASS
      # input_field(:keep_completed_tasks, types.Boolean) if type == "team_task"

      # HANDLE IN CLASS
      # if type == "relationship"
      #   input_field(:add_to_project_id, types.Int)
      #   input_field(:archive_target, types.Int)
      # end

      # HANDLE IN CLASS
      # input_field(:items_destination_project_id, types.Int) if type == "project"
    end
  end
end
