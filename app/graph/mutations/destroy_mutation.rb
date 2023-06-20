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

      # TODO: Extract with update/create behavior
      parents.each do |parent_field|
        # If a return type has been manually specified, use that.
        # Otherwise, use the default (e.g. ProjectType for Project)
        #
        # This allows for specifying parents as:
        # PARENTS = ['team', my_team: TeamType], which would be same as:
        # PARENTS = [team: TeamType, my_team: TeamType]
        if parent_field.is_a?(Hash)
          parent_values = parent_field
          parent_field = parent_values.keys.first
          parent_type = parent_values[parent_field]
        else
          parent_type = "#{parent_field.to_s.camelize}Type".constantize
        end
        subclass.field parent_field.to_sym, parent_type, null: true, camelize: false
      end

      subclass.define_method :resolve do |**inputs|
        ::GraphqlCrudOperations.destroy(inputs, context, parents)
      end

      # HANDLE IN CLASS
      # input_field(:keep_completed_tasks, types.Boolean) if type == "team_task"

      # HANDLE IN CLASS
      # if type == "relationship"
      #   input_field(:add_to_project_id, types.Int)
      #   input_field(:archive_target, types.Int)
      # end
    end
  end
end
