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

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :title, String, required: true
    argument :summary, String, required: true
    argument :claim_description_id, Integer, required: true, camelize: false
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :title, String, required: false
    argument :summary, String, required: false
  end

  class Destroy < Mutation::Destroy; end
end
