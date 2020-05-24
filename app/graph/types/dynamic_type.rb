DynamicType = GraphqlCrudOperations.define_annotation_type('dynamic', {}) do
  description 'Annotation whose type is dynamically created.'
  field :lock_version, types.Int, 'TODO'
end
