class TagType < AnnotationObject
  define_shared_behavior(self, 'tag')

  field :tag, GraphQL::Types::String, null: true
  field :tag_text, GraphQL::Types::String, null: true
  field :fragment, GraphQL::Types::String, null: true

  field :tag_text_object, TagTextType, null: true
end
