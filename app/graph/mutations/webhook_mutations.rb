module WebhookMutations
  MUTATION_TARGET = 'bot_user'.freeze
  PARENTS = ['team'].freeze

  class Destroy < Mutations::DestroyMutation; end 
end
