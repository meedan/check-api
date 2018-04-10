class Status < ActiveRecord::Base
  include SingletonAnnotationBase

  field :status, String, presence: true

  validates_presence_of :status

  validate :status_is_valid

  validate :can_complete_media, on: :update, if: proc { |status| status.annotated_type == 'ProjectMedia' }

  before_validation :store_previous_status, :normalize_status

  after_save :send_terminal_email_notification

  after_commit :send_slack_notification, on: :update

  after_commit :update_elasticsearch_status, on: [:create, :update]

  def self.core_verification_statuses(annotated_type)
    core_statuses = YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)
    key = "#{annotated_type.upcase}_CORE_VERIFICATION_STATUSES"
    statuses = core_statuses.has_key?(key) ? core_statuses[key] : [
      { id: 'undetermined', label: I18n.t(:"statuses.media.undetermined.label"), description: I18n.t(:"statuses.media.undetermined.description"), style: '' }
    ]

    {
      label: 'Status',
      default: 'undetermined',
      active: 'in_progress',
      statuses: statuses
    }
  end

  def self.validate_custom_statuses(team_id, statuses)
    keys = statuses[:statuses].collect{|s| s[:id]}
    project_medias = ProjectMedia.joins(:project).where({ 'projects.team_id' => team_id })
    project_medias.collect{|pm| s = pm.last_status; {project_media: pm.id, url: pm.full_url, status: s} unless keys.include?(s)}.compact
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

  def self.completed_ids(annotated, context = nil)
    return [] if annotated.nil?
    completed = []
    statuses = Status.possible_values(annotated, context)
    statuses[:statuses].each {|s| completed << s[:id] if s[:completed] == "1"}
    completed
  end

  def self.possible_values(annotated, context = nil)
    type = (annotated.class_name == 'ProjectMedia') ? 'media' : annotated.class_name
    statuses = Status.core_verification_statuses(type)
    getter = "get_#{type.downcase}_verification_statuses"
    statuses = context.team.send(getter) if context && context.respond_to?(:team) && context.team && context.team.send(getter)
    statuses
  end

  def self.is_completed?(annotated)
    required_tasks = annotated.required_tasks
    unresolved = required_tasks.select{ |t| t.status != 'Resolved' }
    unresolved.blank?
  end

  def id_to_label(id)
    values = Status.possible_values(self.annotated.media, self.annotated.project)
    values[:statuses].select{ |s| s[:id] === id }.first[:label]
  end

  def update_elasticsearch_status
    self.update_media_search(%w(status)) unless CONFIG['app_name'] === 'Bridge'
  end

  def slack_notification_message
    user = Bot::Slack.to_slack(User.current.name)
    url = Bot::Slack.to_slack_url(self.annotated_client_url, self.annotated.title)
    project = Bot::Slack.to_slack(self.annotated.project.title)
    if self.status != self.previous_annotated_status
      I18n.t(:slack_update_status,
        user: user,
        url: url,
        previous_status: Bot::Slack.to_slack(self.id_to_label(self.previous_annotated_status)),
        current_status: Bot::Slack.to_slack(self.id_to_label(self.status)),
        project: project
      )
    elsif self.assigned_to_id != self.previous_assignee
      assignee = nil
      action = ''
      if self.assigned_to_id.to_i > 0
        assignee = Bot::Slack.to_slack(User.find(self.assigned_to_id).name)
        action = 'assign'
      else
        assignee = Bot::Slack.to_slack(User.find(self.previous_assignee).name)
        action = 'unassign'
      end
      I18n.t("slack_#{action}_report".to_sym,
        user: user,
        url: url,
        assignee: assignee,
        project: project
      )
    end
  end

  def is_terminal?
    terminal = false
    if self.annotated_type == 'ProjectMedia'
      terminal = Status.completed_ids(self.annotated.media, self.annotated.project).include?(self.status)
    end
    terminal
  end

  private

  def status_is_valid
    if !self.annotated_type.blank?
      annotated, context = get_annotated_and_context
      values = Status.possible_values(annotated, context)
      return if values[:statuses].collect{ |s| s[:id] }.include?(self.status)
      self.is_being_copied ? self.status = Status.default_id(annotated, context) : errors.add(:status, 'Status not valid')
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

  def can_complete_media
    if self.is_terminal?
      errors.add(:base, 'You should resolve required tasks first') unless Status.is_completed?(self.annotated)
    end
  end

  def send_terminal_email_notification
    return if self.is_being_copied
    if self.status != self.previous_annotated_status && self.is_terminal?
      TerminalStatusMailer.delay.notify(self.annotated, self.annotator, self.id_to_label(self.status))
    end
  end
end
