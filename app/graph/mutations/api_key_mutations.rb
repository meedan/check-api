module ApiKeyMutations
  MUTATION_TARGET = 'api_key'.freeze
  PARENTS = ['team'].freeze

  class Create < Mutations::CreateMutation
    argument :title, GraphQL::Types::String, required: false
    argument :description, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
