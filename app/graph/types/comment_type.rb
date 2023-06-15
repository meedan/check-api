class CommentType < AnnotationObject
  def type
    'comment'.freeze
  end

  field :text, String, null: true
end
