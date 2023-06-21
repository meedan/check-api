module FactCheckMutations
  MUTATION_TARGET = 'fact_check'.freeze
  PARENTS = ['claim_description'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :url, String, required: false
      argument :language, String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: true
    argument :summary, String, required: true
    argument :claim_description_id, Integer, required: true, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: false
    argument :summary, String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
