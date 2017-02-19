class Status < ActiveRecord::Base
  include SingletonAnnotationBase

  field :status, String, presence: true

  validates_presence_of :status

  validate :status_is_valid

  notifies_slack on: :update,
                 if: proc { |s| s.should_notify? },
                 message: proc { |s| data = s.annotated.embed; I18n.t(:slack_update_status, default: "*%{user}* changed the verification status on <%{url}> from *%{previous_status}* to *%{current_status}*", user: User.current.name, url: "#{CONFIG['checkdesk_client']}/#{s.annotated.project.team.slug}/project/#{s.annotated.project_id}/media/#{s.annotated_id}|#{data['title']}}", previous_status: s.id_to_label(s.previous_annotated_status), current_status: s.id_to_label(s.status)) },
                 channel: proc { |s| s.annotated.project.setting(:slack_channel) || s.current_team.setting(:slack_channel) },
                 webhook: proc { |s| s.current_team.setting(:slack_webhook) }

  before_validation :store_previous_status, :normalize_status

  after_save :update_elasticsearch_status

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
    self.previous_annotated_status = self.annotated.last_status if self.annotated.respond_to?(:last_status)
    annotated, context = get_annotated_and_context
    self.previous_annotated_status ||= Status.default_id(annotated, context)
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
    type = annotated.class_name
    statuses = Status.core_verification_statuses(type)
    getter = "get_#{type.downcase}_verification_statuses"
    statuses = context.team.send(getter) if context && context.respond_to?(:team) && context.team && context.team.send(getter)
    statuses
  end

  def id_to_label(id)
    values = Status.possible_values(self.annotated.media, self.annotated.project)
    values[:statuses].select{ |s| s[:id] === id }.first[:label]
  end

  def update_elasticsearch_status
    self.update_media_search(%w(status))
  end

  private

  def status_is_valid
    if !self.annotated_type.blank?
      annotated, context = get_annotated_and_context
      values = Status.possible_values(annotated, context)
      errors.add(:base, 'Status not valid') unless values[:statuses].collect{ |s| s[:id] }.include?(self.status)
    end
  end

  def get_annotated_and_context
    if self.annotated_type == 'ProjectMedia' || self.annotated_type == 'ProjectSource'
      annotated = self.annotated.media if self.annotated.respond_to?(:media)
      annotated = self.annotated.source if self.annotated.respond_to?(:source)
      context = self.annotated.project if self.annotated.respond_to?(:project)
    else
      annotated = self.annotated
      context = self.context
    end
    return annotated, context
  end
end
