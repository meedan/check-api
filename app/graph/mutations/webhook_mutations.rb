module WebhookMutations
  MUTATION_TARGET = 'bot_user'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :name, GraphQL::Types::String, required: true
      argument :request_url, GraphQL::Types::String, required: true, camelize: false
      argument :events, JsonStringType, required: true
      argument :headers, JsonStringType, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :id, GraphQL::Types::String, required: true
  end

  class Destroy < Mutations::DestroyMutation; end 
end
