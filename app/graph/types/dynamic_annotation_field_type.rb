DynamicAnnotationFieldType = GraphqlCrudOperations.define_default_type do
  name 'DynamicAnnotationField'
  description 'DynamicAnnotation::Field type'

  implements NodeIdentification.interface

  field :annotation, AnnotationType, null: true
end
