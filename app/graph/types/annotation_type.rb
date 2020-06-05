AnnotationType = GraphqlCrudOperations.define_annotation_type('annotation', { content: 'str' }) do
  description 'The base type for annotations describing media, claims, sources, and other types including annotations themselves (recursively).'
end
