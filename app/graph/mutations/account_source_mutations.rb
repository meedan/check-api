module AccountSourceMutations
  MUTATION_TARGET = 'account_source'.freeze
  PARENTS = ['source'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :account_id, GraphQL::Types::Integer, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :source_id, GraphQL::Types::Integer, required: false, camelize: false
    argument :url, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :source_id, GraphQL::Types::Integer, required: true, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
