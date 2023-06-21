module Mutation
  class BulkDestroy < Base
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
        #   class Create < Mutation::Create; end
        #   class Update < Mutation::Update; end
        #
        #   module Bulk
        #      PARENTS = ['overriding', { attribute: SomethingType }].freeze
        #
        #      class Destroy < Mutation::BulkDestroy
        #         # some additional attributes
        #      end
        #   end
        # end
        parents = subclass.module_parent::PARENTS
        mutation_target = subclass.module_parent.module_parent::MUTATION_TARGET

        define_shared_bulk_behavior(:destroy, subclass, mutation_target, parents)
      end
    end
  end
end
