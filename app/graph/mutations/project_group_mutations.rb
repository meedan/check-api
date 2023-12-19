module ProjectGroupMutations
  MUTATION_TARGET = 'project_group'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
    end
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
