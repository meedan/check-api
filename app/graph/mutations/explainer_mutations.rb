module ExplainerMutations
  MUTATION_TARGET = 'explainer'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :title, GraphQL::Types::String, required: false
      argument :description, GraphQL::Types::String, required: false
      argument :url, GraphQL::Types::String, required: false
      argument :language, GraphQL::Types::String, required: false
      argument :tags, [GraphQL::Types::String, null: true], required: false
      argument :channel, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :trashed, GraphQL::Types::Boolean, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
