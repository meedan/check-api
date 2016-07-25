class Status
  include AnnotationBase

  attribute :status, String, presence: true
  validates_presence_of :status

  def content
    { status: self.status }.to_json
  end
end
