module ProjectMediaUserMutations
  MUTATION_TARGET = 'project_media_user'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :project_media_id, GraphQL::Types::Int, required: true, camelize: false
      argument :user_id, GraphQL::Types::Int, required: false, camelize: false # Fallback to current user if not set
      argument :read, GraphQL::Types::Boolean, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end
end
