DynamicAnnotationFieldType = GraphqlCrudOperations.define_default_type do
  name 'DynamicAnnotationField'
  description 'DynamicAnnotation::Field type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :value_json, JsonStringType
  field :annotation, AnnotationType
  field :associated_graphql_id, types.String
  field :smooch_user_slack_channel_url, types.String
  field :smooch_user_external_identifier, types.String
  field :smooch_report_received_at, types.Int
  field :smooch_report_update_received_at, types.Int
  field :smooch_user_request_language, types.String
end
