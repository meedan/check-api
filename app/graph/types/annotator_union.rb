AnnotatorUnion = GraphQL::UnionType.define do
  name 'AnnotatorUnion'
  description 'A union of all types that can make annotations.'
  possible_types [UserType, BotUserType]
end
