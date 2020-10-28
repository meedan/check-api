class Task < ActiveRecord::Base
  include AnnotationBase
  include HasJsonSchema

  attr_accessor :file

  has_annotations

  before_validation :set_slug, on: :create
  before_validation :set_order, on: :create
  after_save :send_slack_notification
  after_destroy :reorder

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime', 'image_upload']
  end
  validates :type, included: { values: self.task_types }

  field :fieldset
  validates_presence_of :fieldset
  validate :fieldset_exists_in_team

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

  scope :from_fieldset, ->(fieldset) { where('task_fieldset(annotations.annotation_type, annotations.data) = ?', fieldset) }

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
      else
        return nil
      end
    else
      event = params[:event]
    end
    pretext = I18n.t("slack.messages.#{self.fieldset}_#{event}", params)
    # Either render a card or add the notification to the thread
    self.annotated&.should_send_slack_notification_message_for_card? ? self.annotated&.slack_notification_message_for_card(pretext) : nil
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

  def show_in_browser_extension
    self.team_task_id && !!TeamTask.find_by_id(self.team_task_id.to_i)&.show_in_browser_extension
  end

  def move_up
    self.move(-1)
  end

  def move_down
    self.move(1)
  end

  def move(direction)
    index = nil
    tasks = self.annotated.ordered_tasks(self.fieldset)
    tasks.each_with_index do |task, i|
      task.update_column(:data, task.data.merge(order: i + 1)) if task.order.to_i == 0
      task.order ||= i + 1
      index = i if task.id == self.id
    end
    return if index.nil?
    swap_with_index = index + direction
    swap_with = tasks[swap_with_index] if swap_with_index >= 0
    self.order = Task.swap_order(tasks[index], swap_with) unless swap_with.nil?
  end

  def self.swap_order(task1, task2)
    task1_order = task1.order
    task2_order = task2.order
    task1.update_column(:data, task1.data.merge(order: task2_order))
    task2.update_column(:data, task2.data.merge(order: task1_order))
    task2_order
  end

  def self.slug(label)
    label.to_s.parameterize.tr('-', '_')
  end

  private

  def task_options_is_array
    errors.add(:base, I18n.t(:task_options_must_be_array)) if !self.options.nil? && !self.options.is_a?(Array)
  end

  def set_slug
    self.slug = Task.slug(self.label)
  end

  def set_order
    return if self.order.to_i > 0 || self.annotated_type != 'ProjectMedia'
    tasks = self.send(:reorder)
    last = tasks.last
    self.order = last ? last.order.to_i + 1 : 1
  end

  def reorder
    tasks = self.annotated.ordered_tasks(self.fieldset)
    tasks.each_with_index { |task, i| task.update_column(:data, task.data.merge(order: i + 1)) if task.order.to_i == 0 }
    tasks
  end

  def fieldset_exists_in_team
    errors.add(:base, I18n.t(:fieldset_not_defined_by_team)) unless self.annotated&.team&.get_fieldsets.to_a.collect{ |f| f['identifier'] }.include?(self.fieldset)
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

DynamicAnnotation::Field.class_eval do
  def selected_values_from_task_answer
    if ['response_single_choice', 'response_multiple_choice'].include?(self.field_name)
      begin
        [JSON.parse(self.value)['selected']].flatten
      rescue
        [value]
      end
    end
  end
end

ProjectMedia.class_eval do
  def task_answers(filters = {})
    DynamicAnnotation::Field
    .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN annotations a2 ON a2.id = a.annotated_id")
    .where("field_name LIKE 'response_%'")
    .where('a.annotated_type' => 'Task', 'a2.annotated_type' => 'ProjectMedia', 'a2.annotated_id' => self.id)
    .where(filters)
  end

  def task_answer_selected_values(filters = {})
    self.task_answers(filters).select{ |a| a.field_name =~ /choice/ }.collect{ |a| a.selected_values_from_task_answer }.flatten
  end

  def selected_value_for_task?(team_task_id, value)
    self.task_answer_selected_values(['task_team_task_id(a2.annotation_type, a2.data) = ?', team_task_id]).include?(value)
  end

  def ordered_tasks(fieldset)
    Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: self.id).select{ |t| t.fieldset == fieldset }.sort_by{ |t| t.order || t.id || 0 }.to_a
  end
end
