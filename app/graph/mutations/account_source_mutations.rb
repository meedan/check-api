module AccountSourceMutations
  MUTATION_TARGET = 'account_source'.freeze
  PARENTS = ['source'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :account_id, Integer, required: false, camelize: false
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :source_id, Integer, required: false, camelize: false
    argument :url, String, required: true
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :source_id, Integer, required: true, camelize: false
  end

  class Destroy < Mutation::Destroy; end
end
