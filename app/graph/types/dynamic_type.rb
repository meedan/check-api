class DynamicType < AnnotationObject
  define_shared_behavior(self, 'dynamic')

  field :lock_version, GraphQL::Types::Integer, null: true
  field :sent_count, GraphQL::Types::Integer, null: true # For "report_design" annotations
end
