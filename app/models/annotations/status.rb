class Status
  include AnnotationBase

  attribute :status, String, presence: true
  validates_presence_of :status
  validates :status, included: { values: ['Credible', 'Not Credible', 'Slightly Credible', 'Sockpuppet'] }, :if => lambda { |o| o.annotated_type == 'Source' }
  validates :status, included: { values: ['Not Applicable', 'In Progress', 'Undetermined', 'Verified', 'False'] }, :if => lambda { |o| o.annotated_type == 'Media' }

  def content
    { status: self.status }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def annotated_type_callback(value, mapping_ids = nil)
    value.camelize
  end


end
