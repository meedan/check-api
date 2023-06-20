class FlagType < AnnotationObject
  define_shared_behavior(self, 'flag')

  field :flag, String, null: true
end
