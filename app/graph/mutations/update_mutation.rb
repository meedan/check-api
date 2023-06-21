module Mutations
  class UpdateMutation < BaseMutation
    class << self
      def inherited(subclass)
        mutation_target = subclass.module_parent::MUTATION_TARGET
        parents = subclass.module_parent::PARENTS

        subclass.argument :id, GraphQL::Types::ID, required: true

        define_create_or_update_behavior('update', subclass, mutation_target, parents)

        subclass.define_method :resolve do |**inputs|
          ::GraphqlCrudOperations.update(inputs, context, parents)
        end
      end
    end
  end
end
