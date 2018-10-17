class Task < ActiveRecord::Base
  include AnnotationBase

  has_annotations

  before_validation :set_initial_status, :set_slug, on: :create
  after_create :send_slack_notification
  after_update :send_slack_notification
  after_destroy :destroy_responses

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime']
  end
  validates :type, included: { values: self.task_types }

  field :description

  field :options
  validate :task_options_is_array

  field :status
  def self.task_statuses
    ["Unresolved", "Resolved", "Can't be resolved"]
  end
  validates :status, included: { values: self.task_statuses }, allow_blank: true

  field :slug
  field :required, :boolean
  field :log_count, Integer
  field :suggestions_count, Integer
  field :pending_suggestions_count, Integer

  def slack_params
    params = super
    params.deep_merge({
      label: Bot::Slack.to_slack(self.label),
      description: Bot::Slack.to_slack(self.description),
      required: self.required ? I18n.t(:answer_yes) : nil,
      task_status: Bot::Slack.to_slack(self.status),
      assigned: self.assigned_to_id.to_i > 0 ? Bot::Slack.to_slack(User.find(self.assigned_to_id).name) : nil,
      unassigned: nil
    })
  end

  def slack_notification_message
    params = self.slack_params
    event = 'create'
    if self.changed?
      if self.assigned_to_id_changed?
        if self.assigned_to_id.to_i > 0
          event = 'assign'
        else
          event = 'unassign'
          params = params.merge({
            unassigned: Bot::Slack.to_slack(User.find(self.assigned_to_id_was).name)
          })
        end
      elsif self.data_changed? and self.data.except("log_count") != self.data_was.except("log_count")
        event = 'edit'
      else
        return nil
      end
    end
    {
      pretext: I18n.t("slack.messages.task_#{event}".to_sym, params),
      title: params[:label],
      title_link: params[:url],
      author_name: params[:user],
      text: params[:description],
      fields: [
        {
          title: I18n.t(:'slack.fields.task_status'),
          value: params[:task_status],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.assigned'),
          value: params[:assigned],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.unassigned'),
          value: params[:unassigned],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.required'),
          value: params[:required],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.project'),
          value: params[:project],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.item'),
          value: params[:item],
          short: false
        }
      ],
      actions: [
        {
          type: "button",
          text: params[:button],
          url: params[:url]
        }
      ]
    }
  end

  def content
    hash = {}
    %w(label type description options status suggestions_count pending_suggestions_count).each{ |key| hash[key] = self.send(key) }
    hash.to_json
  end

  def jsonoptions=(json)
    self.options = JSON.parse(json)
  end

  def jsonoptions
    self.options.to_json
  end

  def responses
    DynamicAnnotation::Field.where(field_type: 'task_reference', value: self.id.to_s).to_a.map(&:annotation)
  end

  def response
    @response
  end

  def response=(json)
    params = JSON.parse(json)
    response = self.responses.first
    response = response.nil? ? Dynamic.new : response.load
    response.annotated = self.annotated
    response.annotation_type = params['annotation_type']
    response.disable_es_callbacks = Rails.env.to_s == 'test'
    response.disable_update_status = (Rails.env.to_s == 'test' && response.respond_to?(:disable_update_status))
    response.set_fields = params['set_fields']
    response.updated_at = Time.now
    response.save!
    @response = response
    self.record_timestamps = false
    set_fields = begin JSON.parse(params['set_fields']) rescue params['set_fields'] end
    self.status = 'Resolved' if set_fields.keys.select{ |k| k =~ /^response/ }.any?
  end

  def first_response
    response = self.responses.first
    response.get_fields.select{ |f| f.field_name =~ /^response/ }.first.to_s unless response.nil?
  end

  def task
    Task.where(id: self.id).last
  end

  def log
    PaperTrail::Version.where(associated_type: 'Task', associated_id: self.id).order('id ASC')
  end

  def reject_suggestion=(version_id)
    self.handle_suggestion(false, version_id)
  end

  def accept_suggestion=(version_id)
    self.handle_suggestion(true, version_id)
  end

  def handle_suggestion(accept, version_id)
    response = self.responses.first
    return if response.nil?
    response = response.load
    suggestion = response.get_fields.select{ |f| f.field_name =~ /^suggestion/ }.first
    return if suggestion.nil?

    # Save review information and copy suggestion to answer if accepted
    review = { user: User.current, timestamp: Time.now, accepted: accept }.to_json
    fields = { "review_#{self.type}" => review }
    if accept
      fields["response_#{self.type}"] = suggestion.to_s
      self.status = 'Resolved'
    end
    response.set_fields = fields.to_json
    response.updated_at = Time.now
    response.save!

    # Save review information in version
    version = PaperTrail::Version.where(id: version_id).last
    version.update_column(:meta, review) unless version.nil?

    # Update number of suggestions
    self.pending_suggestions_count -= 1 if self.pending_suggestions_count.to_i > 0
  end

  def self.slug(label)
    label.to_s.parameterize.tr('-', '_')
  end

  private

  def task_options_is_array
    errors.add(:options, 'must be an array') if !self.options.nil? && !self.options.is_a?(Array)
  end

  def set_initial_status
    self.status ||= 'Unresolved'
  end

  def destroy_responses
    self.responses.each do |annotation|
      annotation.load.fields.delete_all
      annotation.delete
    end
  end

  def set_slug
    self.slug = Task.slug(self.label)
  end
end

Comment.class_eval do
  after_create :increment_task_log_count
  after_destroy :decrement_task_log_count

  protected

  def update_task_log_count(value)
    return unless self.annotated_type == 'Task'
    RequestStore[:task_comment] = self
    task = self.annotated.reload
    task.log_count ||= 0
    task.log_count += value
    task.skip_check_ability = true
    task.save!
    parent = task.annotated
    unless parent.nil?
      count = parent.reload.cached_annotations_count + value
      parent.update_columns(cached_annotations_count: count)
    end
  end

  private

  def increment_task_log_count
    self.update_task_log_count(1)
  end

  def decrement_task_log_count
    self.update_task_log_count(-1)
  end
end

PaperTrail::Version.class_eval do
  after_create :increment_task_suggestions_count

  private

  def increment_task_suggestions_count
    object = JSON.parse(self.object_after)
    if object['field_name'] =~ /^suggestion_/ && self.associated_type == 'Task'
      task = Task.find(self.associated_id)
      task.suggestions_count ||= 0
      task.suggestions_count += 1
      task.pending_suggestions_count ||= 0
      task.pending_suggestions_count += 1
      task.skip_notifications = true
      task.skip_check_ability = true
      task.save!
    end
  end
end
