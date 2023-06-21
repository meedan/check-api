module TaskMutations
  MUTATION_TARGET = 'task'.freeze
  PARENTS = ['project_media', 'source', 'project', 'version'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, String, required: false
      argument :json_schema, String, required: false, camelize: false
      argument :order, Integer, required: false
      argument :fieldset, String, required: false

      field :versionEdge, VersionType.edge_type, null: true
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :label, String, required: true
    argument :type, String, required: true
    argument :jsonoptions, String, required: false
    argument :annotated_id, String, required: false, camelize: false
    argument :annotated_type, String, required: false, camelize: false
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :label, String, required: false
    argument :response, String, required: false
  end

  class Destroy < Mutation::Destroy; end
end
