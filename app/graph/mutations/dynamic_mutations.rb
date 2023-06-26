module DynamicMutations
  MUTATION_TARGET = 'dynamic'.freeze
  PARENTS = ['project_media', 'source', 'project', 'task', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :set_attribution, GraphQL::Types::String, required: false, camelize: false

      # TODO: Extract these into annotation mutation module
      argument :fragment, GraphQL::Types::String, required: false
      argument :annotated_id, GraphQL::Types::String, required: false, camelize: false
      argument :annotated_type, GraphQL::Types::String, required: false, camelize: false

      field :versionEdge, VersionType.edge_type, null: true
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :set_fields, GraphQL::Types::String, required: true, camelize: false
    argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :locked, GraphQL::Types::Boolean, required: false
    argument :set_fields, GraphQL::Types::String, required: false, camelize: false
    argument :annotation_type, GraphQL::Types::String, required: false, camelize: false
    argument :lock_version, GraphQL::Types::Integer, required: false, camelize: false
    argument :assigned_to_ids, GraphQL::Types::String, required: false, camelize: false
    argument :assignment_message, GraphQL::Types::String, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
