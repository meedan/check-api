class CommentType < AnnotationObject
  define_shared_behavior(self, 'comment')

  field :text, String, null: true
end
