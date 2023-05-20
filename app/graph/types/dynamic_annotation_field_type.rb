module Types
  class DynamicAnnotationFieldType < DefaultObject
    description "DynamicAnnotation::Field type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :value_json, JsonString, null: true
    field :annotation, "Types::AnnotationType", null: true
    field :associated_graphql_id, String, null: true
    field :smooch_user_slack_channel_url, String, null: true
    field :smooch_user_external_identifier, String, null: true
    field :smooch_report_received_at, Integer, null: true
    field :smooch_report_update_received_at, Integer, null: true
    field :smooch_user_request_language, String, null: true
  end
end
