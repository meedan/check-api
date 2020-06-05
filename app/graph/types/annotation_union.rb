AnnotationUnion = GraphQL::UnionType.define do
  name 'AnnotationUnion'
  description 'A union type of all annotation types we can handle'
  possible_types [AnnotationType, DynamicType, CommentType, TagType, FlagType, TaskType]
end
