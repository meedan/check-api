class Flag
  include AnnotationBase

  attribute :flag, String, presence: true
  validates_presence_of :flag
  validates :flag, included: { values: ['Spam', 'Graphic Content', 'Fact Checking'] }
  
  def content
    { flag: self.flag }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

end
