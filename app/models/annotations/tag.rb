class Tag
  include AnnotationBase

  attribute :tag, String, presence: true
  validates_presence_of :tag
  validates :tag, uniqueness: { fields: [:annotated_type, :annotated_id, :context_type, :context_id] }, if: lambda { |t| t.id.blank? }

  def content
    { tag: self.tag }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

end
