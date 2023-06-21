module CommentMutations
  MUTATION_TARGET = 'comment'.freeze
  PARENTS = ['project_media', 'source', 'project', 'task', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      field :versionEdge, VersionType.edge_type, null: true

      # TODO: Extract these into annotation mutation module
      argument :fragment, String, required: false
      argument :annotated_id, String, required: false, camelize: false
      argument :annotated_type, String, required: false, camelize: false
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :text, String, required: false
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :text, String, required: true
  end

  class Destroy < Mutation::Destroy; end
end
