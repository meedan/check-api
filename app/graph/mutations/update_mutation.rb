module Mutations
  class UpdateMutation < BaseMutation
    class << self
      def inherited(subclass)
        mutation_target = subclass.module_parent::MUTATION_TARGET
        parents_mapping = GraphqlCrudOperations.hashify_parent_types(subclass.module_parent::PARENTS)

        subclass.argument :id, GraphQL::Types::ID, required: false

        define_create_or_update_behavior('update', subclass, mutation_target, parents_mapping)

        subclass.define_method :resolve do |**inputs|
          ::GraphqlCrudOperations.update(inputs, context, parents_mapping)
        end
      end
    end
  end
end
