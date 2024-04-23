module ApiKeyMutations
  MUTATION_TARGET = 'api_key'.freeze
  PARENTS = ['team'].freeze

  module CreateFields
    extend ActiveSupport::Concern

    included do
      argument :title, GraphQL::Types::String, required: false
      argument :description, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include CreateFields
  end

  class Destroy < Mutations::DestroyMutation; end
end