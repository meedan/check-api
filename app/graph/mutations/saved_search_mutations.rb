module SavedSearchMutations
  MUTATION_TARGET = 'saved_search'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :filters, JsonString, required: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: true
    argument :team_id, Integer, required: true, camelize: false
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: false
  end

  class Destroy < DestroyMutation; end
end
