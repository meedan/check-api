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
    pretext = I18n.t("slack.messages.#{self.fieldset}_#{event}", **params)
    # Either render a card or add the notification to the thread
    self.annotated&.should_send_slack_notification_message_for_card? ? self.annotated&.slack_notification_message_for_card(pretext) : nil
  end

  def content
    hash = {}
    %w(label type description options order).each{ |key| hash[key] = self.send(key) }
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
    response.skip_check_ability = self.skip_check_ability
    self.file = nil
    response.save!
    @response = response
    self.update_task_answer_cache
    self.record_timestamps = false
  end

  def get_file_from_uri(params)
    file_url = begin JSON.parse(params['set_fields'])['response_file_upload'] rescue '' end
    unless file_url.blank?
      URI(file_url).open do |f|
        data = f.read
        filepath = File.join(Rails.root, 'tmp', "#{Digest::MD5.hexdigest(data)}.png")
        File.atomic_write(filepath) { |file| file.write(data) }
        self.file = File.open(filepath)
        params['set_fields'] = { response_file_upload: 'Uploaded file' }.to_json
      end
    end
    params
  end

  def first_response_obj
    return @response if @response
    responses = self.responses
    @response = responses.first
    @response
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
      data = { 'team_task_id' => self.team_task_id, 'fieldset' => self.fieldset }
      self.add_update_nested_obj({ op: op, pm_id: pm.id, nested_key: 'task_responses', keys: data.keys, data: data })
      self.update_recent_activity(pm) if User.current.present?
    end
  end

  def update_task_answer_cache
    self.annotated.task_value(self.team_task_id, true) unless self.team_task_id.blank?
  end

  def team_task
    id = self.team_task_id
    id ? TeamTask.find_by_id(id) : nil
  end

  def self.bulk_insert(klass, id, uid, task_ids, responses)
    object = klass.constantize.find_by_id(id)
    unless object.nil?
      team = object.team
      new_tasks = []
      TeamTask.where(id: task_ids).find_each do |task|
        data = {
          label: task.label,
          type: task.task_type,
          description: task.description,
          team_task_id: task.id,
          json_schema: task.json_schema,
          order: task.order,
          fieldset: task.fieldset,
          slug: team.slug,
        }
        data[:options] = task.options unless task.options.blank?
        task_c = {
          annotation_type: 'task',
          annotator_id: uid,
          annotator_type: 'User',
          annotated_id: object.id,
          annotated_type: object.class.name,
          data: data
        }.with_indifferent_access
        new_tasks << task_c
      end
      unless new_tasks.blank?
        result = Task.insert_all(new_tasks, returning: [:id])
        object.respond_to_auto_tasks(result.rows.flatten, responses)
      end
    end
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
    self.destroy_es_items('task_responses', 'destroy_doc_nested', self.project_media.id) unless self.project_media.nil?
  end
end

DynamicAnnotation::Field.class_eval do
  def selected_values_from_task_answer
    if ['response_single_choice', 'response_multiple_choice'].include?(self.field_name)
      begin
        [JSON.parse(self.value).values].flatten.reject(&:blank?)
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
