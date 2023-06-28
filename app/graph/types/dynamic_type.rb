class DynamicType < AnnotationObject
  define_shared_behavior(self, 'dynamic')

  field :lock_version, GraphQL::Types::Int, null: true
  field :sent_count, GraphQL::Types::Int, null: true # For "report_design" annotations
end
