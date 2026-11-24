module AccountSourceMutations
  MUTATION_TARGET = 'account_source'.freeze
  PARENTS = ['source'].freeze

  class Create < Mutations::CreateMutation
    argument :source_id, GraphQL::Types::Int, required: true, camelize: false
    argument :url, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
