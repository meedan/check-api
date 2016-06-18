class Comment
  include AnnotationBase

  attribute :text, String, presence: true
  validates_presence_of :text
end
