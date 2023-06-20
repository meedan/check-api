module TeamUserMutations
  MUTATION_TARGET = 'team_user'.freeze
  PARENTS = ['user','team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :role, String, required: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :user_id, Integer, required: true, camelize: false
    argument :team_id, Integer, required: true, camelize: false
    argument :status, String, required: true
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields

    argument :user_id, Integer, required: false, camelize: false
    argument :team_id, Integer, required: false, camelize: false
    argument :status, String, required: false
  end

  class Destroy < DestroyMutation; end
end
