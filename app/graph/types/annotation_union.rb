class AnnotationUnion < BaseUnion
  description 'A union type of all annotation types we can handle'
  possible_types(
    AnnotationType,
    DynamicType,
    TagType,
    FlagType,
    TaskType,
  )
end
