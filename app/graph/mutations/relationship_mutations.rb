module RelationshipMutations
  MUTATION_TARGET = 'relationship'.freeze
  PARENTS = [
    { source_project_media: ProjectMediaType },
    { target_project_media: ProjectMediaType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :source_id, Integer, required: false, camelize: false
      argument :target_id, Integer, required: false, camelize: false
      argument :relationship_source_type, String, required: false, camelize: false
      argument :relationship_target_type, String, required: false, camelize: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :relationship_type, JsonString, required: false, camelize: false
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < DestroyMutation; end

  module Bulk
    PARENTS = [{ source_project_media: ProjectMediaType }].freeze

    class Update < BulkUpdateMutation
      argument :action, String, required: true
      argument :source_id, Integer, required: true, camelize: false
    end

    class Destroy < BulkDestroyMutation
      argument :source_id, Integer, required: true, camelize: false
      argument :add_to_project_id, Integer, required: false, camelize: false
    end
  end
end
