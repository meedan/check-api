DynamicType = GraphqlCrudOperations.define_annotation_type('dynamic', {}) do
  field :lock_version, types.Int
  field :sent_count, types.Int # For "report_design" annotations
end
