module CommentMutations
  module MutationProperties
    def mutation_target
      :comment
    end

    def parents
      ['project_media', 'source', 'project', 'task', 'version'].freeze
    end
  end

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      field :versionEdge, VersionType.edge_type, null: true

      argument :fragment, String, required: false
      argument :annotated_id, String, required: false
      argument :annotated_type, String, required: false
    end
  end

  class Create < BaseUpdateOrCreateMutation
    extend MutationProperties
    extend SharedCreateAndUpdateFields

    define_create_behavior(self, self.mutation_target, self.parents)

    argument :text, String, required: true
  end

  class Update < BaseUpdateOrCreateMutation
    extend MutationProperties
    extend SharedCreateAndUpdateFields

    define_update_behavior(self, self.mutation_target, self.parents)

    argument :text, String, required: false
  end

  class Destroy < BaseDestroyMutation
    extend MutationProperties
  end
end
