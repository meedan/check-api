module TeamUserMutations
  MUTATION_TARGET = 'team_user'.freeze
  PARENTS = ['user','team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :role, String, required: false
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :user_id, Integer, required: true, camelize: false
    argument :team_id, Integer, required: true, camelize: false
    argument :status, String, required: true
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :user_id, Integer, required: false, camelize: false
    argument :team_id, Integer, required: false, camelize: false
    argument :status, String, required: false
  end

  class Destroy < Mutation::Destroy; end
end
