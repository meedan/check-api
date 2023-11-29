class TiplineRequestType < DefaultObject
  description "TiplineRequest type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :value_json, JsonStringType, null: true
  field :annotation, AnnotationType, null: true
  field :annotation_id, GraphQL::Types::Int, null: true
  field :associated_graphql_id, GraphQL::Types::String, null: true
  field :smooch_user_slack_channel_url, GraphQL::Types::String, null: true
  field :smooch_user_external_identifier, GraphQL::Types::String, null: true
  field :smooch_report_received_at, GraphQL::Types::Int, null: true
  field :smooch_report_update_received_at, GraphQL::Types::Int, null: true
  field :smooch_user_request_language, GraphQL::Types::String, null: true
  field :smooch_report_sent_at, GraphQL::Types::Int, null: true
  field :smooch_report_correction_sent_at, GraphQL::Types::Int, null: true
  field :smooch_request_type, GraphQL::Types::String, null: true
end
