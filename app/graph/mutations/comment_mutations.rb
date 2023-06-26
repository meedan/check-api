module CommentMutations
  MUTATION_TARGET = 'comment'.freeze
  PARENTS = ['project_media', 'source', 'project', 'task', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      field :versionEdge, VersionType.edge_type, null: true

      # TODO: Extract these into annotation mutation module
      argument :fragment, GraphQL::Types::String, required: false
      argument :annotated_id, GraphQL::Types::String, required: false, camelize: false
      argument :annotated_type, GraphQL::Types::String, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :text, GraphQL::Types::String, required: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :text, GraphQL::Types::String, required: true
  end

  class Destroy < Mutations::DestroyMutation; end
end
