module ClaimDescriptionMutations
  MUTATION_TARGET = 'claim_description'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
      argument :context, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :project_media_id, GraphQL::Types::Int, required: true, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end
end
