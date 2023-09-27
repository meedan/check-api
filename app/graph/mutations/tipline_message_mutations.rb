module TiplineMessageMutations
  class Send < Mutations::BaseMutation
    argument :in_reply_to_id, GraphQL::Types::Int, required: true # Database ID of a tipline request ("smooch" annotation)
    argument :message, GraphQL::Types::String, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(in_reply_to_id: nil, message: nil)
      request = Annotation.find(in_reply_to_id).load
      ability = context[:ability] || Ability.new
      success = false
      if Team.current&.id && User.current&.id && ability.can?(:send, TiplineMessage.new(team: Team.current)) && request.annotated.team_id == Team.current.id
        success = Bot::Smooch.reply_to_request_with_custom_message(request, message)
      end
      { success: success }
    end
  end
end
