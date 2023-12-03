module TeamUserMutations
  MUTATION_TARGET = 'team_user'.freeze
  PARENTS = ['user','team'].freeze

  class Update < Mutations::UpdateMutation
    argument :role, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
