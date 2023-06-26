class FlagType < AnnotationObject
  define_shared_behavior(self, 'flag')

  field :flag, GraphQL::Types::String, null: true
end
