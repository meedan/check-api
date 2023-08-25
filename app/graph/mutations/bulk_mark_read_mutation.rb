module Mutations
  class BulkMarkReadMutation < BaseMutation
    class << self
      def inherited(subclass)
        parents_mapping = GraphqlCrudOperations.hashify_parent_types(subclass.module_parent::PARENTS)
        mutation_target = subclass.module_parent.module_parent::MUTATION_TARGET

        define_shared_bulk_behavior(:mark_read, subclass, mutation_target, parents_mapping)

        subclass.field :updated_objects, ["#{mutation_target.camelize}Type".constantize, null: true], null: true, camelize: false
      end
    end
  end
end