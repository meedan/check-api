DynamicAnnotationFieldType = GraphqlCrudOperations.define_default_type do
  name 'DynamicAnnotationField'
  description 'A field of a dynamic annotation.'

  interfaces [NodeIdentification.interface]

  field :annotation, AnnotationType, 'Annotation'
end
