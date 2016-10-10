class Embed
  include AnnotationBase

  attribute :embed, String, presence: true
  validates_presence_of :embed

  def content
    { embed: self.embed }.to_json
  end

end
