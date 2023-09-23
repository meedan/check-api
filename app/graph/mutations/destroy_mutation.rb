module Mutations
  class DestroyMutation < BaseMutation
    class << self
      def inherited(subclass)
        parents_mapping = GraphqlCrudOperations.hashify_parent_types(subclass.module_parent::PARENTS)
        define_behavior(subclass, subclass.module_parent::MUTATION_TARGET, parents_mapping)
      end

      def define_behavior(subclass, mutation_target, parents_mapping)
        subclass.graphql_name "Destroy#{mutation_target.to_s.camelize}"

        subclass.argument :id, GraphQL::Types::ID, required: false
        subclass.field :deleted_id, GraphQL::Types::ID, null: true, camelize: true

        type_class = "#{mutation_target.to_s.camelize}Type".constantize

        set_parent_returns(subclass, parents_mapping)

        subclass.define_method :resolve do |**inputs|
          ::GraphqlCrudOperations.destroy(inputs, context, parents_mapping)
        end

        type_class
      end
    end
  end
end
