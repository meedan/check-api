module Mutations
  class BaseMutation < ::GraphQL::Schema::RelayClassicMutation
    class << self
      private

      def define_shared_bulk_behavior(action, subclass, mutation_target, parents)
        subclass.graphql_name "#{action.to_s.capitalize}#{mutation_target.camelize.pluralize}"

        subclass.argument :ids, [GraphQL::Types::ID], required: true
        subclass.field :ids, [GraphQL::Types::ID], null: true

        set_parent_returns(subclass, parents)

        subclass.define_method(:resolve) do |**inputs|
          GraphqlCrudOperations.apply_bulk_update_or_destroy(
            inputs,
            context,
            action,
            mutation_target.camelize.constantize
          )
        end
      end

      def define_create_or_update_behavior(action, subclass, mutation_target, parents)
        subclass.graphql_name "#{action.camelize}#{mutation_target.camelize}"

        type_class = "#{mutation_target.camelize}Type".constantize
        subclass.field mutation_target, type_class, null: true, camelize: false
        subclass.field "#{type_class}Edge", type_class.edge_type, null: true

        set_parent_returns(subclass, parents)
      end

      def set_parent_returns(klass, parents)
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
          klass.field parent_field.to_sym, parent_type, null: true, camelize: false
        end
      end
    end
  end
end
