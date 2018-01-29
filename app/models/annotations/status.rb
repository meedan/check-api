class Status < ActiveRecord::Base
  include SingletonAnnotationBase

  field :status, String, presence: true

  validates_presence_of :status

  validate :status_is_valid

  validate :can_resolve_status, on: :update, if: proc { |status| status.annotated_type == 'ProjectMedia' }

  after_update :send_slack_notification

  before_validation :store_previous_status, :normalize_status

  after_save :update_elasticsearch_status

  def self.core_verification_statuses(annotated_type)
    core_statuses = YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)
    key = "#{annotated_type.upcase}_CORE_VERIFICATION_STATUSES"
    statuses = core_statuses.has_key?(key) ? core_statuses[key] : [
      { id: 'undetermined', label: I18n.t(:"statuses.media.undetermined.label"), description: I18n.t(:"statuses.media.undetermined.description"), style: '' }
    ]

    {
      label: 'Status',
      default: 'undetermined',
      completed: 'verified',
      active: 'in_progress',
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

  def normalize_status
    self.status = self.status.tr(' ', '_').downcase unless self.status.blank?
  end

  def self.default_id(annotated, context = nil)
    return nil if annotated.nil?
    statuses = Status.possible_values(annotated, context)
    statuses[:default].blank? ? statuses[:statuses].first[:id] : statuses[:default]
  end

  def self.active_id(annotated, context = nil)
    return nil if annotated.nil?
    statuses = Status.possible_values(annotated, context)
    statuses[:active]
  end

  def self.completed_id(annotated, context = nil)
    return nil if annotated.nil?
    statuses = Status.possible_values(annotated, context)
    statuses[:completed]
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
    self.update_media_search(%w(status)) unless CONFIG['app_name'] === 'Bridge'
  end

  def slack_notification_message
    I18n.t(:slack_update_status,
      user: Bot::Slack.to_slack(User.current.name),
      url: Bot::Slack.to_slack_url("#{self.annotated_client_url}", "#{self.annotated.title}"),
      previous_status: Bot::Slack.to_slack(self.id_to_label(self.previous_annotated_status)),
      current_status: Bot::Slack.to_slack(self.id_to_label(self.status)),
      project: Bot::Slack.to_slack(self.annotated.project.title)
    )
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

  def can_resolve_status
    annotated = self.annotated
    completed = Status.completed_id(annotated.media, annotated.project)
    if self.status == completed
      required_tasks = annotated.required_tasks
      unresolved = required_tasks.select{ |t| t.status != 'Resolved' }
      errors.add(:base, 'You should resolve required tasks first') unless unresolved.blank?
    end
  end
end
