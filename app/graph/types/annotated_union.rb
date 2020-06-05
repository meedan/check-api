AnnotatedUnion = GraphQL::UnionType.define do
  name 'AnnotatedUnion'
  description 'A union of all types that can be annotated.'
  possible_types [
    TeamType,
    ProjectType,
    MediaType,
    ProjectMediaType,
    SourceType,
    AccountType,
    AnnotationType,
    DynamicType,
    TaskType,
    TagType,
    FlagType,
    CommentType
  ]
end
