class Task < ApplicationRecord
  include AnnotationBase
  include HasJsonSchema

  attr_accessor :file

  has_annotations

  before_validation :set_slug, on: :create
  before_validation :set_order, on: :create

  after_save :task_send_slack_notification
  after_destroy :reorder
  after_commit :add_update_elasticsearch_task, on: :create
  after_commit :destroy_elasticsearch_task, on: :destroy

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime', 'file_upload', 'number', 'url']
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

  # TODO: Sawy::remove this method and handle slack notification for sources
  def task_send_slack_notification
    self.send_slack_notification unless self.annotated_type == 'Source'
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
      if self.saved_change_to_data? and self.data.except(*SLACK_FIELDS_IGNORE) != self.data_before_last_save.except(*SLACK_FIELDS_IGNORE)
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
    klass = self.task_type == 'file_upload' ? FileUploadTaskResponse : Dynamic
    response.nil? ? klass.new : response.load.becomes(klass)
  end

  def response=(json)
    params = JSON.parse(json)
    params = begin self.get_file_from_uri(params) rescue params end
    response = self.new_or_existing_response
    response.annotated = self
    response.annotation_type = params['annotation_type'] unless params['annotation_type'].blank?
    response.set_fields = params['set_fields'] unless params['set_fields'].blank?
    response.updated_at = Time.now
    response.file = [self.file].flatten
    self.file = nil
    response.save!
    @response = response
    self.update_task_answer_cache
    self.record_timestamps = false
  end

  def get_file_from_uri(params)
    file_url = begin JSON.parse(params['set_fields'])['response_file_upload'] rescue '' end
    unless file_url.blank?
      open(file_url) do |f|
        data = f.read
        filepath = File.join(Rails.root, 'tmp', "#{Digest::MD5.hexdigest(data)}.png")
        File.atomic_write(filepath) { |file| file.write(data) }
        self.file = File.open(filepath)
        params['set_fields'] = { response_file_upload: 'Uploaded file' }.to_json
      end
    end
    params
  end

  def existing_files
    self.first_response_obj&.load&.file.to_a
  end

  def add_files(new_files)
    self.file = [self.existing_files].flatten.reject{ |f| f.blank? }.concat(new_files)
    self.response = '{}'
  end

  def remove_files(filenames)
    self.file = [existing_files].flatten.reject{ |f| f.blank? || filenames.include?(f.to_s.split('/').last) }
    self.response = '{}'
  end

  def first_response_obj
    return @response if @response
    responses = self.responses
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
    tasks = self.annotated.ordered_tasks(self.fieldset, self.associated_type)
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

  def add_update_elasticsearch_task(op = 'create')
    # Will index team tasks of type choices only so user can filter by ANY/NON answer value(#8801)
    if self.type =~ /choice/ && self.team_task_id && self.annotated_type == 'ProjectMedia'
      pm = self.project_media
      keys = %w(team_task_id fieldset)
      data = { 'team_task_id' => self.team_task_id, 'fieldset' => self.fieldset }
      self.add_update_nested_obj({op: op, obj: pm, nested_key: 'task_responses', keys: keys, data: data})
    end
  end

  def update_task_answer_cache
    self.annotated.task_value(self.team_task_id, true) unless self.team_task_id.blank?
  end

  def team_task
    id = self.team_task_id
    id ? TeamTask.find_by_id(id) : nil
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
    tasks = self.annotated.ordered_tasks(self.fieldset, self.associated_type)
    tasks.each_with_index { |task, i| task.update_column(:data, task.data.merge(order: i + 1)) if task.order.to_i == 0 }
    tasks
  end

  def fieldset_exists_in_team
    errors.add(:base, I18n.t(:fieldset_not_defined_by_team)) unless self.annotated&.team&.get_fieldsets.to_a.collect{ |f| f['identifier'] }.include?(self.fieldset)
  end

  def destroy_elasticsearch_task
    # Remove task with answer from ES
    self.destroy_es_items('task_responses', 'destroy_doc_nested', self.project_media)
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
    return if parent&.reload&.archived > CheckArchivedFlags::FlagCodes::NONE
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
end

Dynamic.class_eval do
  after_update :update_task_answer_cache, if: proc { |d| d.annotation_type =~ /^task_response/ }
  after_destroy :delete_task_answer_cache, if: proc { |d| d.annotation_type =~ /^task_response/ }

  private

  def update_task_answer_cache
    self.annotated.update_task_answer_cache if self.annotated_type == 'Task'
  end

  def delete_task_answer_cache
    if self.annotated_type == 'Task'
      task = Task.find(self.annotated_id)
      Rails.cache.delete("project_media:task_value:#{task.annotated_id}:#{task.team_task_id}")
    end
  end
end
