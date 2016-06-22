CommentType = GraphQL::ObjectType.define do
  name 'Comment'
  description 'Comment type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Comment')
  # End of fields
end
