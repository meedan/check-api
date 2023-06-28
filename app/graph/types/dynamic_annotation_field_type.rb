class DynamicAnnotationFieldType < DefaultObject
  description "DynamicAnnotation::Field type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Int, null: true
  field :value_json, JsonString, null: true
  field :annotation, "AnnotationType", null: true
  field :associated_graphql_id, GraphQL::Types::String, null: true
  field :smooch_user_slack_channel_url, GraphQL::Types::String, null: true
  field :smooch_user_external_identifier, GraphQL::Types::String, null: true
  field :smooch_report_received_at, GraphQL::Types::Int, null: true
  field :smooch_report_update_received_at, GraphQL::Types::Int, null: true
  field :smooch_user_request_language, GraphQL::Types::String, null: true
end
