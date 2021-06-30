class AnnotationUnion < Types::BaseUnion
  description 'A union type of all annotation types we can handle'
  possible_types(
    AnnotationType,
    DynamicType,
    CommentType,
    TagType,
    FlagType,
    TaskType,
  )
end
