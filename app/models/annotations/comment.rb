class Comment
  include Annotation

  attribute :text, String, presence: true
  validates_presence_of :text
end
