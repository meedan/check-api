module TiplineMessageMutations
  class Send < Mutations::BaseMutation
    argument :uid, GraphQL::Types::ID, required: true
    argument :message, GraphQL::Types::String, required: true
    argument :timestamp, GraphQL::Types::Int, required: true
    argument :language, GraphQL::Types::String, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(uid: nil, message: nil, timestamp: nil, language: nil)
      ability = context[:ability] || Ability.new
      success = false
      if Team.current&.id && User.current&.id && ability.can?(:send, TiplineMessage.new(team: Team.current))
        success = Bot::Smooch.send_custom_message_to_user(Team.current, uid, timestamp, message, language)
      end
      { success: success }
    end
  end
end
