module WebhookMutations
  MUTATION_TARGET = 'bot_user'.freeze
  PARENTS = ['team'].freeze

  class Create < Mutations::CreateMutation
    argument :name, GraphQL::Types::String, required: true
    argument :request_url, GraphQL::Types::String, required: true, camelize: false
    argument :events, JsonStringType, required: true
    argument :headers, JsonStringType, required: false
  end

  class Destroy < Mutations::DestroyMutation; end 
end
