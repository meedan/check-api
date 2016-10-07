class Status
  include AnnotationBase

  attribute :status, String, presence: true
  
  validates_presence_of :status
  validates :annotated_type, included: { values: ['Media', 'Source', nil] }
  validates :status, included: { values: ['Credible', 'Not Credible', 'Slightly Credible', 'Sockpuppet'] }, if: lambda { |o| o.annotated_type == 'Source' }
  validates :status, included: { values: ['Not Applicable', 'In Progress', 'Undetermined', 'Verified', 'False'] }, if: lambda { |o| o.annotated_type == 'Media' }

  notifies_slack on: :save,
                 if: proc { |s| s.current_user.present? && s.current_team.present? && s.current_team.setting(:slack_notifications_enabled).to_i === 1 && s.annotated_type === 'Media' },
                 message: proc { |s| "<#{s.origin}/user/#{s.current_user.id}|*#{s.current_user.name}*> changed the verification status on <#{s.origin}/project/#{s.context_id}/media/#{s.annotated_id}|#{s.annotated.data['title']}> from *#{s.previous_annotated_status}* to *#{s.status}*" },
                 channel: proc { |s| s.context.setting(:slack_channel) || s.current_team.setting(:slack_channel) },
                 webhook: proc { |s| s.current_team.setting(:slack_webhook) }

  before_validation :store_previous_status
  
  def store_previous_status
    self.previous_annotated_status = self.annotated.last_status(self.context) if self.annotated.respond_to?(:last_status)
    self.previous_annotated_status ||= 'Undetermined' 
  end

  def previous_annotated_status
    @previous_annotated_status
  end
  
  def previous_annotated_status=(status)
    @previous_annotated_status = status
  end

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

  def annotated_type_callback(value, _mapping_ids = nil)
    value.camelize
  end
end
