class Task < ActiveRecord::Base
  include AnnotationBase
  include HasJsonSchema

  attr_accessor :file

  has_annotations

  before_validation :set_slug, on: :create
  after_save :send_slack_notification

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime', 'image_upload']
  end
  validates :type, included: { values: self.task_types }

  field :description

  field :options
  validate :task_options_is_array

  field :slug
  field :log_count, Integer
  field :suggestions_count, Integer
  field :pending_suggestions_count, Integer
  field :team_task_id, Integer
  field :order, Integer

  field :json_schema

  def json_schema_enabled?
    true
  end

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

  def to_s
    self.label
  end

  SLACK_FIELDS_IGNORE = [ :log_count, :slug, :status ]

  def slack_params
    super.merge({
      title: Bot::Slack.to_slack(self.label),
      description: Bot::Slack.to_slack(self.description, false),
      attribution: nil
    })
  end

  def slack_notification_message(params = nil)
    if params.nil?
      params = self.slack_params
      if self.data_changed? and self.data.except(*SLACK_FIELDS_IGNORE) != self.data_was.except(*SLACK_FIELDS_IGNORE)
        event = self.annotation_versions.count > 1 ? 'edit' : 'create'
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
    %w(label type description options status suggestions_count pending_suggestions_count order).each{ |key| hash[key] = self.send(key) }
    hash.to_json
  end

  def jsonoptions=(json)
    self.options = JSON.parse(json)
  end

  def jsonoptions
    self.options.to_json
  end

  def responses
    Annotation.where(annotated_type: 'Task', annotated_id: self.id).where("annotation_type LIKE 'task_response%'")
  end

  def response
    @response
  end

  def new_or_existing_response
    response = self.first_response_obj
    response.nil? ? Dynamic.new : response.load
  end

  def response=(json)
    params = JSON.parse(json)
    response = self.new_or_existing_response
    response.annotated = self
    response.annotation_type = params['annotation_type']
    response.disable_es_callbacks = Rails.env.to_s == 'test'
    response.set_fields = params['set_fields']
    response.updated_at = Time.now
    response.file = [self.file]
    self.file = nil
    response.save!
    @response = response
    self.record_timestamps = false
  end

  def first_response_obj
    return @response if @response
    user = User.current
    responses = self.responses
    if !user.nil? && user.role?(:annotator)
      responses = responses.where(annotator_id: user.id)
    else
      responses = responses.reject{ |r| r.annotator&.role?(:annotator) }
    end
    @response = responses.first
    @response
  end

  def version_object
    uid = User.current&.id
    @response ||= self.first_response_obj
    return @version_object if @response.nil?
    @field ||= @response.get_fields.select{ |f| f.field_name =~ /^response/ }.first
    return @version_object if @field.nil?
    Version.from_partition(self.team&.id).where(whodunnit: uid, item_type: 'DynamicAnnotation::Field', item_id: @field.id.to_s).last
  end

  def first_response
    @response ||= self.first_response_obj
    return nil if @response.nil?
    @field ||= @response.get_fields.select{ |f| f.field_name =~ /^response/ }.first
    @field.to_s
  end

  def task
    Task.where(id: self.id).last
  end

  def log
    Version.from_partition(self.team&.id).where(associated_type: 'Task', associated_id: self.id).where.not("object_after LIKE '%task_status%'").order('id ASC')
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
    end
    response.set_fields = fields.to_json
    response.updated_at = Time.now
    response.save!

    # Save review information in version
    version = Version.from_partition(self.team&.id).where(id: version_id).last
    version.update_column(:meta, review) unless version.nil?

    # Update number of suggestions
    self.pending_suggestions_count -= 1 if self.pending_suggestions_count.to_i > 0
  end

  def self.slug(label)
    label.to_s.parameterize.tr('-', '_')
  end

  def self.order_tasks(tasks)
    errors = []
    tasks.each do |item|
      item = item.symbolize_keys
      begin
        task = Task.where(annotation_type: 'task', id: item[:id]).last
        if task.nil?
          errors << {id: item[:id], error: I18n.t(:error_record_not_found, { type: 'Task', id: item[:id] })}
        else
          task.paper_trail.without_versioning do
            task.order = item[:order].to_i
            task.save!
          end
        end
      rescue StandardError => e
        errors << {id: item[:id], error: e.message}
      end
    end
    errors
  end

  private

  def task_options_is_array
    errors.add(:options, 'must be an array') if !self.options.nil? && !self.options.is_a?(Array)
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
    parent = task.annotated
    return if parent&.reload&.archived
    task.log_count ||= 0
    task.log_count += value
    task.skip_check_ability = true
    task.save!
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

Version.class_eval do
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
