module FactCheckMutations
  MUTATION_TARGET = 'fact_check'.freeze
  PARENTS = ['claim_description', 'team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :url, GraphQL::Types::String, required: false
      argument :language, GraphQL::Types::String, required: false
      argument :tags, [GraphQL::Types::String, null: true], required: false
      argument :rating, GraphQL::Types::String, required: false
      argument :channel, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :title, GraphQL::Types::String, required: true
    argument :summary, GraphQL::Types::String, required: true
    argument :claim_description_id, GraphQL::Types::Int, required: false, camelize: false
    argument :claim_description_text, GraphQL::Types::String, required: false, camelize: false
    argument :imported, GraphQL::Types::Boolean, required: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, GraphQL::Types::String, required: false
    argument :summary, GraphQL::Types::String, required: false
    argument :trashed, GraphQL::Types::Boolean, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
