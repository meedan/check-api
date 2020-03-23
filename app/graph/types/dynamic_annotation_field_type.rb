DynamicAnnotationFieldType = GraphqlCrudOperations.define_default_type do
  name 'DynamicAnnotationField'
  description 'DynamicAnnotation::Field type'

  interfaces [NodeIdentification.interface]

  field :annotation, AnnotationType
end
