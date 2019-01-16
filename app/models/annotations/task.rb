class Task < ActiveRecord::Base
  include AnnotationBase

  has_annotations

  before_validation :set_slug, on: :create
  after_create :send_slack_notification
  after_update :send_slack_notification, :update_users_assignments_progress
  after_commit :send_slack_notification, on: [:create, :update]
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

  field :slug
  field :required, :boolean
  field :log_count, Integer
  field :suggestions_count, Integer
  field :pending_suggestions_count, Integer
  field :team_task_id, Integer

  def status=(value)
    a = Annotation.where(annotation_type: 'task_status', annotated_type: 'Task', annotated_id: self.id).last
    a = a.nil? ? nil : (a.load || a)
    return nil if a.nil?
    f = a.get_field('task_status_status')
    f.value = value
    f.skip_check_ability = true
    f.save!
  end

  def status
    self.last_task_status
  end

  def project
    self&.annotated&.project
  end

  def to_s
    self.label
  end

  def required_for_user(user_id)
    self.required && self.assigned_users.where('users.id' => user_id).count > 0
  end

  SLACK_FIELDS_IGNORE = [ :log_count, :slug, :status ]

  def slack_params
    super.merge({
      title: Bot::Slack.to_slack(self.label),
      description: Bot::Slack.to_slack(self.description, false),
      required: self.required ? I18n.t("slack.fields.required_yes") : nil,
      status: Bot::Slack.to_slack(self.status),
      attribution: nil
    })
  end

  def slack_notification_message(params = nil)
    if params.nil?
      params = self.slack_params
      if self.data_changed? and self.data.except(*SLACK_FIELDS_IGNORE) != self.data_was.except(*SLACK_FIELDS_IGNORE)
        event = self.versions.count > 1 ? 'edit' : 'create'
      elsif !params[:assignment_event].blank?
        event = params[:assignment_event]
      else
        return nil
      end
    else
      event = params[:event]
    end
    {
      pretext: I18n.t("slack.messages.task_#{event}", params),
      title: params[:title],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:description],
      fields: [
        {
          title: I18n.t("slack.fields.status"),
          value: params[:status],
          short: true
        },
        {
          title: I18n.t("slack.fields.assigned"),
          value: params[:assigned],
          short: true
        },
        {
          title: I18n.t("slack.fields.unassigned"),
          value: params[:unassigned],
          short: true
        },
        {
          title: I18n.t("slack.fields.required"),
          value: params[:required],
          short: true
        },
        {
          title: I18n.t("slack.fields.project"),
          value: params[:project],
          short: true
        },
        {
          title: I18n.t("slack.fields.attribution"),
          value: params[:attribution],
          short: true
        },
        {
          title: params[:parent_type],
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
    ids = DynamicAnnotation::Field.select('annotation_id').where(field_type: 'task_reference', value: self.id.to_s).map(&:annotation_id)
    Annotation.where(id: ids)
  end

  def response
    @response
  end

  def new_or_existing_response
    response = self.first_response_obj
    response.nil? ? Dynamic.new : response.load
  end

  def must_resolve_task(params)
    set_fields = begin JSON.parse(params['set_fields']) rescue params['set_fields'] end
    if set_fields.keys.select{ |k| k =~ /^response/ }.any?
      uids = self.assigned_users.map(&:id).sort
      uids.empty? || uids == self.responses.map(&:annotator_id).uniq.sort
    else
      false
    end
  end

  def response=(json)
    params = JSON.parse(json)
    response = self.new_or_existing_response
    response.annotated = self.annotated
    response.annotation_type = params['annotation_type']
    response.disable_es_callbacks = Rails.env.to_s == 'test'
    response.disable_update_status = (Rails.env.to_s == 'test' && response.respond_to?(:disable_update_status))
    response.set_fields = params['set_fields']
    response.updated_at = Time.now
    response.save!
    @response = response
    self.record_timestamps = false
    self.status = 'resolved' if self.must_resolve_task(params)
    self.update_user_assignments_progress(response)
  end

  def update_user_assignments_progress(response)
    user_id = response.annotator_id.to_i
    team_id = self.annotated&.project&.team_id
    TeamUser.delay_for(1.second).set_assignments_progress(user_id, team_id)
    User.delay_for(1.second).set_assignments_progress(user_id, self.annotated_id.to_i)
  end

  def first_response_obj
    user = User.current
    responses = self.responses
    if !user.nil? && user.role?(:annotator)
      responses = responses.select{ |r| r.annotator_id.to_i == user.id.to_i }
    else
      responses = responses.reject{ |r| r.annotator&.role?(:annotator) }
    end
    responses.first
  end

  def first_response
    response = self.first_response_obj
    response.get_fields.select{ |f| f.field_name =~ /^response/ }.first.to_s unless response.nil?
  end

  def task
    Task.where(id: self.id).last
  end

  def log
    PaperTrail::Version.where(associated_type: 'Task', associated_id: self.id).where.not("object_after LIKE '%task_status%'").order('id ASC')
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
      self.status = 'resolved'
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

  def destroy_responses
    self.responses.each do |annotation|
      annotation.load.fields.delete_all
      annotation.delete
    end
  end

  def set_slug
    self.slug = Task.slug(self.label)
  end

  def update_users_assignments_progress
    if self.data_was['required'] != self.data['required']
      team_id = self.annotated&.project&.team_id
      unless team_id.nil?
        self.assigned_users.each do |user|
          User.delay_for(1.second).set_assignments_progress(user.id, self.annotated_id.to_i)
          TeamUser.delay_for(1.second).set_assignments_progress(user.id, team_id)
        end
      end
    end
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
