module ProjectMediaUserMutations
  MUTATION_TARGET = 'project_media_user'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :project_media_id, Integer, required: true, camelize: false
      argument :user_id, Integer, required: false, camelize: false # Fallback to current user if not set
      argument :read, GraphQL::Types::Boolean, required: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < DestroyMutation; end
end
