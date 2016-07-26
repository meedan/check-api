StatusType = GraphQL::ObjectType.define do
  name 'Status'
  description 'Status type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Comment')
  field :status, types.String
  field :context_id, types.String
  field :context_type, types.String
  field :annotated_id, types.String
  field :annotated_type, types.String
  field :version_index, types.Int
  field :annotation_type, types.String
  field :updated_at, types.String
  field :created_at, types.String
  # End of fields
end
