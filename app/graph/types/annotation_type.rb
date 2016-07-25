AnnotationType = GraphQL::ObjectType.define do
  name 'Annotation'
  description 'Annotation type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Annotation')
  field :content, types.String
  field :version_index, types.Int
  field :annotation_type, types.String
  field :updated_at, types.String
  field :created_at, types.String
  
  field :annotator do
    type UserType

    resolve -> (annotation, _args, _ctx) {
      annotation.annotator
    }
  end
end
