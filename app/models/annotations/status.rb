class Status
  include AnnotationBase

  attribute :status, String, presence: true
  validates_presence_of :status
  validates :status, included: { values: ['Credible', 'Not Credible', 'Slightly Credible', 'Sockpuppet'] }
  
  def content
    { status: self.status }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

end
