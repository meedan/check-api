module ApiKeyMutations
  MUTATION_TARGET = 'api_key'.freeze
  PARENTS = ['team'].freeze

  module CreateFields
    extend ActiveSupport::Concern

    included do
      argument :title, GraphQL::Types::String, required: false
      argument :description, GraphQL::Types::String, required: false
    end
  end

  class Create < Mutations::CreateMutation
    include CreateFields

    def resolve(**inputs)
      begin
        bot_user = BotUser.new
        bot_user.name = inputs[:title]
        bot_user.login = inputs[:title]
        bot_user.save!

        bot_user.api_key.title = inputs[:title]
        bot_user.api_key.description = inputs[:description]
        bot_user.api_key.save!

        { success: true, api_key: bot_user.api_key }
      rescue
        { success: false, error: 'Could not create API key' }
      end
    end
  end

  class Destroy < Mutations::DestroyMutation; end
end
