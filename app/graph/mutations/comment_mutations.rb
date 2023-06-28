module CommentMutations
  MUTATION_TARGET = 'comment'.freeze
  PARENTS = ['project_media', 'source', 'project', 'task', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern
    include Mutations::Inclusions::AnnotationBehaviors

    included do
      field :versionEdge, VersionType.edge_type, null: true
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :text, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :text, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
