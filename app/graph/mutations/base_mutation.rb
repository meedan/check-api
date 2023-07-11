module Mutations
  class BaseMutation < ::GraphQL::Schema::RelayClassicMutation
    class << self
      private

      def define_shared_bulk_behavior(action, subclass, mutation_target, parents_mapping)
        subclass.graphql_name "#{action.to_s.capitalize}#{mutation_target.camelize.pluralize}"

        subclass.argument :ids, [GraphQL::Types::ID], required: true unless action == :create
        subclass.field :ids, [GraphQL::Types::ID], null: true

        set_parent_returns(subclass, parents_mapping)

        subclass.define_method(:resolve) do |**inputs|
          GraphqlCrudOperations.apply_bulk_update_or_destroy(
            inputs,
            context,
            action,
            mutation_target.camelize.constantize
          )
        end
      end

      def define_create_or_update_behavior(action, subclass, mutation_target, parents_mapping)
        subclass.graphql_name "#{action.camelize}#{mutation_target.camelize}"

        type_class = "#{mutation_target.camelize}Type".constantize
        subclass.field mutation_target, type_class, null: true, camelize: false
        subclass.field "#{mutation_target}Edge", type_class.edge_type, camelize: false, null: true

        set_parent_returns(subclass, parents_mapping)
      end

      def set_parent_returns(klass, parents_mapping)
        parents_mapping.each do |parent_field, parent_type|
          klass.field parent_field.to_sym, parent_type, null: true, camelize: false
        end
      end
    end
  end
end
