module FeedMutations
  MUTATION_TARGET = 'feed'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, String, required: false
      argument :tags, [String], required: false
      argument :saved_search_id, Integer, required: false, camelize: false
      argument :published, GraphQL::Types::Boolean, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :name, String, required: true
    argument :licenses, [Integer], required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :name, String, required: false
  end
end
