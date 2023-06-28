module Mutations
  class BulkUpdateMutation < BaseMutation
    class << self
      def inherited(subclass)
        # These attributes below are a bit hacky - basically, we expect for bulk classes to have the
        # same mutation target as their superclass but not the same parents. A module with both CRUD
        # and bulk mutations might be look something like this:
        #
        # module MyMutations
        #   MUTATION_TARGET = 'relationship'.freeze
        #   PARENTS = ['my', { original: ParentType }].freeze
        #
        #   class Create < Mutations::CreateMutation; end
        #   class Update < Mutations::UpdateMutation; end
        #
        #   module Bulk
        #      PARENTS = ['overriding', { attribute: SomethingType }].freeze
        #
        #      class Update < Mutations::BulkUpdateMutation
        #         # some additional attributes
        #      end
        #   end
        # end
        parents = subclass.module_parent::PARENTS
        mutation_target = subclass.module_parent.module_parent::MUTATION_TARGET

        define_shared_bulk_behavior(:update, subclass, mutation_target, parents)

        subclass.field :updated_objects, ["#{mutation_target.camelize}Type".constantize], null: true, camelize: false
      end
    end
  end
end
