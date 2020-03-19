DynamicAnnotationFieldType = GraphqlCrudOperations.define_default_type do
  name 'DynamicAnnotationField'
  description 'DynamicAnnotation::Field type'

  interfaces [NodeIdentification.interface]

  field :field_name, types.String
  field :value, JsonStringType
  field :annotation, AnnotationType
end
