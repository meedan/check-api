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

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :relationship_type, JsonString, required: false, camelize: false
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields
  end

  class Destroy < Mutation::Destroy; end

  module Bulk
    PARENTS = [{ source_project_media: ProjectMediaType }].freeze

    class Update < Mutation::BulkUpdate
      argument :action, String, required: true
      argument :source_id, Integer, required: true, camelize: false
    end

    class Destroy < Mutation::BulkDestroy
      argument :source_id, Integer, required: true, camelize: false
      argument :add_to_project_id, Integer, required: false, camelize: false
    end
  end
end
