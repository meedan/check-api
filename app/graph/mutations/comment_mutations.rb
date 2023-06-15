module CommentMutations
  MUTATION_TARGET = 'comment'.freeze
  PARENTS = ['project_media', 'source', 'project', 'task', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      field :versionEdge, VersionType.edge_type, null: true

      argument :fragment, String, required: false
      argument :annotated_id, String, required: false, camelize: false
      argument :annotated_type, String, required: false, camelize: false
    end
  end

  class Create < BaseMutation
    include SharedCreateAndUpdateFields
    define_create_behavior(self, MUTATION_TARGET, PARENTS)

    argument :text, String, required: false
  end

  class Update < BaseMutation
    include SharedCreateAndUpdateFields
    define_update_behavior(self, MUTATION_TARGET, PARENTS)

    argument :text, String, required: true
  end

  class Destroy < BaseMutation
    define_destroy_behavior(self, MUTATION_TARGET, PARENTS)
  end
end
