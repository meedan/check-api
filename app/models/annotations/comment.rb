class Comment
  include AnnotationBase

  attribute :text, String, presence: true
  validates_presence_of :text

  def content
    { text: self.text }.to_json
  end
end
