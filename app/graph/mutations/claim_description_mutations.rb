module ClaimDescriptionMutations
  MUTATION_TARGET = 'claim_description'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, String, required: false
      argument :context, String, required: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :project_media_id, Integer, required: false, camelize: false
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields
  end
end
