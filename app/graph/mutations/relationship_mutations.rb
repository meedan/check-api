module RelationshipMutations
  MUTATION_TARGET = 'relationship'.freeze
  PARENTS = [
    { source_project_media: ProjectMediaType },
    { target_project_media: ProjectMediaType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :source_id, GraphQL::Types::Int, required: false, camelize: false
      argument :target_id, GraphQL::Types::Int, required: false, camelize: false
      argument :relationship_source_type, GraphQL::Types::String, required: false, camelize: false
      argument :relationship_target_type, GraphQL::Types::String, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :relationship_type, JsonStringType, required: false, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < Mutations::DestroyMutation
    argument :archive_target, GraphQL::Types::Int, required: false, camelize: false
  end

  module Bulk
    PARENTS = [{ source_project_media: ProjectMediaType }].freeze

    class Update < Mutations::BulkUpdateMutation
      argument :action, GraphQL::Types::String, required: true
      argument :source_id, GraphQL::Types::Int, required: true, camelize: false
    end

    class Destroy < Mutations::BulkDestroyMutation
      argument :source_id, GraphQL::Types::Int, required: true, camelize: false
    end
  end
end
