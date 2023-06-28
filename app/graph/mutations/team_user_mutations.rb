module TeamUserMutations
  MUTATION_TARGET = 'team_user'.freeze
  PARENTS = ['user','team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :role, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :user_id, GraphQL::Types::Int, required: true, camelize: false
    argument :team_id, GraphQL::Types::Int, required: true, camelize: false
    argument :status, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :user_id, GraphQL::Types::Int, required: false, camelize: false
    argument :team_id, GraphQL::Types::Int, required: false, camelize: false
    argument :status, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
