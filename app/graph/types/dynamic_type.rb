DynamicType = GraphqlCrudOperations.define_annotation_type('dynamic', {}) do
  field :lock_version, types.Int
end
