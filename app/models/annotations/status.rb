class Status
  include AnnotationBase

  MEDIA_CORE_VERIFICATION_STATUSES = {
    label: 'Status',
    default: 'undetermined',
    statuses: [
      { id: 'not_applicable', label: 'Not Applicable', description: 'Not Applicable', style: '' },
      { id: 'in_progress', label: 'In Progress', description: 'In Progress', style: '' },
      { id: 'undetermined', label: 'Undetermined', description: 'Undetermined', style: '' },
      { id: 'verified', label: 'Verified', description: 'Verified', style: '' },
      { id: 'false', label: 'False', description: 'False', style: '' }
    ]
  }

  SOURCE_CORE_VERIFICATION_STATUSES = {
    label: 'Status',
    default: 'undetermined',
    statuses: [
      { id: 'undetermined', label: 'Undetermined', description: 'Undetermined', style: '' },
      { id: 'credible', label: 'Credible', description: 'Credible', style: '' },
      { id: 'not_credible', label: 'Not Credible', description: 'Not Credible', style: '' },
      { id: 'slightly_credible', label: 'Slightly Credible', description: 'Slightly Credible', style: '' },
      { id: 'sockpuppet', label: 'Sockpuppet', description: 'Sockpuppet', style: '' }
    ]
  }

  DEFAULT_CORE_VERIFICATION_STATUSES = {
    label: 'Status',
    default: 'undetermined',
    statuses: [
      { id: 'undetermined', label: 'Undetermined', description: 'Undetermined', style: '' }
    ]
  }

  attribute :status, String, presence: true
  
  validates_presence_of :status
  validates :annotated_type, included: { values: ['Media', 'Source', nil] }
  validate :status_is_valid

  notifies_slack on: :save,
                 if: proc { |s| s.should_notify? },
                 message: proc { |s| "<#{s.origin}/user/#{s.current_user.id}|*#{s.current_user.name}*> changed the verification status on <#{s.origin}/project/#{s.context_id}/media/#{s.annotated_id}|#{s.annotated.data['title']}> from *#{s.previous_annotated_status}* to *#{s.status}*" },
                 channel: proc { |s| s.context.setting(:slack_channel) || s.current_team.setting(:slack_channel) },
                 webhook: proc { |s| s.current_team.setting(:slack_webhook) }

  before_validation :store_previous_status

  def self.core_verification_statuses(annotated_type)
    begin
      "Status::#{annotated_type.upcase}_CORE_VERIFICATION_STATUSES".constantize
    rescue NameError
      DEFAULT_CORE_VERIFICATION_STATUSES
    end
  end
  
  def store_previous_status
    self.previous_annotated_status = self.annotated.last_status(self.context) if self.annotated.respond_to?(:last_status)
    self.previous_annotated_status ||= Status.default_id(self.annotated, self.context)
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

  def self.default_id(annotated, context = nil)
    return nil if annotated.nil?
    statuses = Status.possible_values(annotated, context)
    statuses[:default].blank? ? statuses[:statuses].first[:id] : statuses[:default]
  end

  def self.possible_values(annotated, context = nil)
    type = annotated.class.name
    statuses = Status.core_verification_statuses(type)
    getter = "get_#{type.downcase}_verification_statuses"
    statuses = context.team.send(getter) if context && context.respond_to?(:team) && context.team && context.team.send(getter)
    statuses
  end

  private

  def status_is_valid
    if !self.annotated_type.blank?
      values = Status.possible_values(self.annotated, self.context)
      errors.add(:base, 'Status not valid') unless values[:statuses].collect{ |s| s[:id] }.include?(self.status)
    end
  end
end
