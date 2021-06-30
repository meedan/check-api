DynamicType = GraphqlCrudOperations.define_annotation_type('dynamic', {}) do
  field :lock_version, Integer, null: true
  field :sent_count, Integer, , null: true # For "report_design" annotations
end
