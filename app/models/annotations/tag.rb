class Tag
  include AnnotationBase

  attribute :tag, String, presence: true
  validates_presence_of :tag

  def content
    { tag: self.tag }.to_json
  end
end
