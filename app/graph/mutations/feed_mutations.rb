module FeedMutations
  MUTATION_TARGET = 'feed'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
      argument :tags, [GraphQL::Types::String, null: true], required: false
      argument :saved_search_id, GraphQL::Types::Int, required: false, camelize: false
      argument :published, GraphQL::Types::Boolean, required: false, camelize: false
      argument :discoverable, GraphQL::Types::Boolean, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: true
    argument :licenses, [GraphQL::Types::Int, null: true], required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: false
  end
end
