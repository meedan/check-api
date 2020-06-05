AnnotationUnion = GraphQL::UnionType.define do
  name 'AnnotationUnion'
  description 'A union of all types of annotations.'
  possible_types [AnnotationType, DynamicType, CommentType, TagType, FlagType, TaskType]
end
