class TiplineRequestType < DefaultObject
  description "TiplineRequest type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :associated_id, GraphQL::Types::Int, null: true
  field :associated_type, GraphQL::Types::String, null: true
  field :smooch_report_received_at, GraphQL::Types::Int, null: true
  field :smooch_report_update_received_at, GraphQL::Types::Int, null: true
  field :smooch_user_request_language, GraphQL::Types::String, null: true
  field :smooch_report_sent_at, GraphQL::Types::Int, null: true
  field :smooch_report_correction_sent_at, GraphQL::Types::Int, null: true
  field :smooch_request_type, GraphQL::Types::String, null: true
  field :associated_graphql_id, GraphQL::Types::String, null: true

  field :smooch_user_external_identifier, GraphQL::Types::String, null: true

  def smooch_user_external_identifier
    ability = context[:ability] || Ability.new
    # Mask the user identifier when this request is displayed in a feed context
    ability.can?(:read, object) ? object.smooch_user_external_identifier : SecureRandom.hex.first(5)
  end

  field :smooch_data, JsonStringType, null: true

  def smooch_data
    ability = context[:ability] || Ability.new
    # Mask user information when this request is displayed in a feed context
    ability.can?(:read, object) ? object.smooch_data : object.smooch_data.to_h.merge({ 'name' => SecureRandom.hex.first(5), 'authorId' => SecureRandom.hex.first(5) })
  end
end
