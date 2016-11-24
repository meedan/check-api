class Status < ActiveRecord::Base
  include AnnotationBase
  
  attr_accessible

  field :status, String, presence: true

  validates_presence_of :status
  validates :annotated_type, included: { values: ['Media', 'Source', nil] }
  validate :status_is_valid

  notifies_slack on: :save,
                 if: proc { |s| s.should_notify? },
                 message: proc { |s| data = s.annotated.data(s.context); "*#{s.current_user.name}* changed the verification status on <#{s.origin}/project/#{s.context_id}/media/#{s.annotated_id}|#{data['title']}> from *#{s.id_to_label(s.previous_annotated_status)}* to *#{s.id_to_label(s.status)}*" },
                 channel: proc { |s| s.context.setting(:slack_channel) || s.current_team.setting(:slack_channel) },
                 webhook: proc { |s| s.current_team.setting(:slack_webhook) }

  before_validation :store_previous_status, :normalize_status

  def self.core_verification_statuses(annotated_type)
    core_statuses = YAML.load_file(File.join(Rails.root, 'config', 'core_statuses.yml'))
    key = "#{annotated_type.upcase}_CORE_VERIFICATION_STATUSES"
    statuses = core_statuses.has_key?(key) ? core_statuses[key] : [{ id: 'undetermined', label: 'Undetermined', description: 'Undetermined', style: '' }]

    {
      label: 'Status',
      default: 'undetermined',
      statuses: statuses
    }
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

  def normalize_status
    self.status = self.status.tr(' ', '_').downcase unless self.status.blank?
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

  def id_to_label(id)
    values = Status.possible_values(self.annotated, self.context)
    values[:statuses].select{ |s| s[:id] === id }.first[:label]
  end

  private

  def status_is_valid
    if !self.annotated_type.blank?
      values = Status.possible_values(self.annotated, self.context)
      errors.add(:base, 'Status not valid') unless values[:statuses].collect{ |s| s[:id] }.include?(self.status)
    end
  end
end
