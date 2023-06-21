module ProjectGroupMutations
  MUTATION_TARGET = 'project_group'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, String, required: false
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :title, String, required: true
    argument :team_id, Integer, required: true, camelize: false
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :title, String, required: false
  end

  class Destroy < Mutation::Destroy; end
end
