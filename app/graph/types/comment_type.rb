class CommentType < AnnotationObject
  define_shared_behavior(self, 'comment')

  field :text, GraphQL::Types::String, null: true
end
