module TaskMutations
  MUTATION_TARGET = 'task'.freeze
  PARENTS = ['project_media', 'source', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
      argument :json_schema, GraphQL::Types::String, required: false, camelize: false
      argument :order, GraphQL::Types::Int, required: false
      argument :fieldset, GraphQL::Types::String, required: false

      field :versionEdge, VersionType.edge_type, null: true
    end
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :label, GraphQL::Types::String, required: false
    argument :response, GraphQL::Types::String, required: false
  end
end
