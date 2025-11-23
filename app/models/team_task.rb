class TeamTask < ApplicationRecord
  attr_accessor :keep_completed_tasks, :options_diff

  before_validation :set_order, on: :create

  validates_presence_of :label, :team_id, :fieldset
  validates :task_type, included: { values: Task.task_types }
  validate :fieldset_exists_in_team
  validate :can_change_task_type, on: :update

  serialize :options, Array
  serialize :mapping

  belongs_to :team, optional: true

  after_create :add_teamwide_tasks
  after_update :update_teamwide_tasks
  after_commit :delete_teamwide_tasks, on: :destroy
  after_destroy :reorder

  def as_json(_options = {})
    super.merge({
      type: self.task_type
    }).with_indifferent_access
  end

  def json_options=(json)
    self.options = JSON.parse(json) unless json.blank?
  end

  def type
    self.task_type
  end

  def type=(value)
    self.task_type = value
  end

  def add_teamwide_tasks_bg
    # add metadata to items or sources based on associated_type field
    if self.associated_type == 'Source'
      add_to_sources
    else
      add_to_project_medias
    end
  end

  def update_teamwide_tasks_bg(fields, options_diff)
    # collect updated fields with new values
    columns = {}
    fields.each do |k, _v|
      attribute = self.read_attribute(k)
      # type is called `task_type` on TeamTask and `type` on Task
      k = :type if k == :task_type
      columns[k] = attribute
    end
    update_tasks(columns) unless columns.blank?
    update_task_answers(options_diff) unless options_diff.blank?
  end

  def self.destroy_teamwide_tasks_bg(id, keep_completed_tasks)
    if keep_completed_tasks
      TeamTask.get_teamwide_tasks_zero_answers(id).find_each do |t|
        self.destroy_project_media_task(t)
      end
    else
      Task.where(annotation_type: 'task', annotated_type: ['ProjectMedia', 'Source'])
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id).find_each do |t|
        self.destroy_project_media_task(t)
      end
    end
  end

  def move_up
    self.move(-1)
  end

  def move_down
    self.move(1)
  end

  def move(direction)
    index = nil
    tasks = self.team.ordered_team_tasks(self.fieldset)
    tasks.each_with_index do |task, i|
      task.update_column(:order, i + 1) if task.order.to_i == 0
      task.order ||= i + 1
      index = i if task.id == self.id
    end
    return if index.nil?
    swap_with_index = index + direction
    swap_with = tasks[swap_with_index] if swap_with_index >= 0
    self.order = TeamTask.swap_order(tasks[index], swap_with) unless swap_with.nil?
  end

  def self.swap_order(task1, task2)
    task1_order = task1.order
    task2_order = task2.order
    updated_at = Time.now
    task1.update_columns(order: task2_order, updated_at: updated_at)
    task2.update_columns(order: task1_order, updated_at: updated_at)
    # Apply new order to item annotations
    fields = { order: true }
    TeamTaskWorker.perform_in(30.seconds, 'update', task1.id, User.current&.id, updated_at.to_f, YAML::dump(fields))
    TeamTaskWorker.perform_in(30.seconds, 'update', task2.id, User.current&.id, updated_at.to_f, YAML::dump(fields))
    task2_order
  end

  def tasks_count
    TeamTask.get_teamwide_tasks(self.id).count
  end

  def tasks_with_answers_count
    get_teamwide_tasks_with_answers.count
  end

  private

  def add_teamwide_tasks
    TeamTaskWorker.perform_in(30.seconds, 'add', self.id, User.current&.id, self.updated_at.to_f)
  end

  def update_teamwide_tasks
    fields = {
      label: self.saved_change_to_label?,
      description: self.saved_change_to_description?,
      task_type: self.saved_change_to_task_type?,
      options: self.saved_change_to_options?,
      order: self.saved_change_to_order?
    }
    fields.delete_if{|_k, v| v == false || v.nil?}
    TeamTaskWorker.perform_in(30.seconds, 'update', self.id, User.current&.id, self.updated_at.to_f, YAML::dump(fields), false, self.options_diff) unless fields.blank?
  end

  def delete_teamwide_tasks
    self.keep_completed_tasks = self.keep_completed_tasks.nil? ? false : self.keep_completed_tasks
    TeamTaskWorker.perform_in(30.seconds, 'destroy', self.id, User.current&.id, self.updated_at.to_f, YAML::dump({}), self.keep_completed_tasks)
  end

  def add_to_sources
    Source.where(team_id: self.team_id).find_each do |s|
      begin
        s.create_auto_tasks([self])
      rescue StandardError => e
        team_task_notification_error(e, s)
      end
    end
  end

  def add_to_project_medias
    ProjectMedia.where({ team_id: self.team_id, archived: [CheckArchivedFlags::FlagCodes::NONE, CheckArchivedFlags::FlagCodes::UNCONFIRMED] })
    .joins("LEFT JOIN annotations a ON a.annotation_type = 'task' AND a.annotated_type = 'ProjectMedia'
      AND a.annotated_id = project_medias.id
      AND task_team_task_id(a.annotation_type, a.data) = #{self.id}")
    .where("a.id" => nil).order(id: :desc).distinct.find_each do |pm|
      begin
        pm.create_auto_tasks([self])
      rescue StandardError => e
        team_task_notification_error(e, pm)
      end
    end
  end

  def update_tasks(columns)
    columns = columns.except(:type) if get_teamwide_tasks_with_answers.any?
    TeamTask.get_teamwide_tasks(self.id).find_each do |t|
      t.skip_check_ability = true
      t.update(columns)
    end
  end

  # TODO: Handle update/delete 'other' option
  def update_task_answers(options_diff)
    tasks = get_teamwide_tasks_with_answers
    responses = Dynamic.where(annotation_type: "task_response_#{self.task_type}",annotated_type: "Task", annotated_id: tasks.map(&:id))
    conditions = {
      annotation_id: responses.map(&:id),
      annotation_type: "task_response_#{self.task_type}",
      field_name: "response_#{self.task_type}",
    }
    fields = DynamicAnnotation::Field.where(conditions)
    method = "update_task_answers_#{self.task_type}"
    deleted, updated, response_ids = self.send(method, fields, options_diff)
    Dynamic.where(id: deleted).destroy_all unless deleted.blank?
    unless updated.blank?
      # Update PG
      DynamicAnnotation::Field.import(updated, on_duplicate_key_update: [:value], recursive: false, validate: false)
      Dynamic.where(id: response_ids).update_all(updated_at: Time.now)
      # Update ES
      keys = %w(id team_task_id value field_type fieldset date_value numeric_value)
      # Add mapping for tasks and it's ProjectMedia
      t_pm = {}
      Task.where(id: responses.map(&:annotated_id)).find_each{ |r| t_pm[r.id] = r.annotated_id }
      Dynamic.where(id: response_ids).find_each do |response|
        response.add_update_nested_obj({op: 'update', pm_id: t_pm[response.annotated_id.to_i], nested_key: 'task_responses', keys: keys})
      end
    end
  end

  def update_task_answers_single_choice(fields, options_diff)
    deleted = []
    updated = []
    response_ids = []
    fields.find_each do |f|
      deleted << f.annotation_id if options_diff['deleted'].include?(f.value)
      if options_diff['changed'].keys.include?(f.value)
        f.value = options_diff['changed'][f.value]
        updated << f
        response_ids << f.annotation_id
      end
    end
    return deleted, updated, response_ids
  end

  def update_task_answers_multiple_choice(fields, options_diff)
    deleted = []
    updated = []
    response_ids = []
    fields.find_each do |f|
      parsed = begin JSON.parse(f.value) rescue { 'selected' => [] } end
      # Handle delete options
      new_value = parsed
      unless (parsed['selected'].to_a & options_diff['deleted']).empty?
        new_selected = parsed['selected'].to_a - options_diff['deleted']
        # build new response
        new_value = { 'selected' => new_selected, 'other' => parsed['other'] }
      end
      # Handle update options
      unless (parsed['selected'].to_a & options_diff['changed'].keys).empty?
        new_selected = new_value['selected'].to_a.collect{ |x| options_diff['changed'].keys.include?(x) ? options_diff['changed'][x] : x }
        new_value = { 'selected' => new_selected, 'other' => parsed['other'] }
      end
      # if both selected and other are empty then delete response otherwise do an update
      unless (new_value.values - parsed.values).empty?
        if new_value.values.reject(&:blank?).empty?
          deleted << f.annotation_id
        else
          f.value = new_value.to_json
          updated << f
          response_ids << f.annotation_id
        end
      end
    end
    return deleted, updated, response_ids
  end

  def self.get_teamwide_tasks(id)
    Task.where('annotations.annotation_type' => 'task')
    .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id)
  end

  def self.get_teamwide_tasks_zero_answers(id)
    TeamTask.get_teamwide_tasks(id)
    .joins("LEFT JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
    .where('responses.id' => nil)
  end

  def get_teamwide_tasks_with_answers
    ids = TeamTask.get_teamwide_tasks(self.id).pluck(:id)
    Task.where(annotated_id: ids, annotated_type: 'Task').where('annotation_type LIKE ?', 'task_response%')
  end

  def self.destroy_project_media_task(t)
    t.skip_check_ability = true
    t.destroy
  end

  def fieldset_exists_in_team
    errors.add(:base, I18n.t(:fieldset_not_defined_by_team)) unless self.team&.get_fieldsets.to_a.collect{ |f| f['identifier'] }.include?(self.fieldset)
  end

  def can_change_task_type
    if (self.task_type_changed?) && !tasks_with_answers_count.zero?
      errors.add(:base, I18n.t(:cant_change_field_type_or_options_when_answered))
    end
  end

  def set_order
    return if self.order.to_i > 0 || !self.team_id
    tasks = self.send(:reorder)
    self.order = tasks.last&.order.to_i + 1
  end

  def reorder
    tasks = self.team.ordered_team_tasks(self.fieldset)
    tasks.each_with_index { |task, i| task.update_column(:order, i + 1) if task.order.to_i == 0 }
    tasks
  end

  def team_task_notification_error(e, obj)
    CheckSentry.notify(e, team_task_id: self.id, item_type: obj.class.name, item_id: obj.id)
    Rails.logger.error "[Team Task] Could not add team task [#{self.id}] to a #{obj.class.name} [#{obj.id}]: #{e.message} #{e.backtrace.join("\n")}"
  end
end

Team.class_eval do
  def ordered_team_tasks(fieldset)
    TeamTask.where(team_id: self.id, fieldset: fieldset).order(order: :asc, id: :asc)
  end
end

CheckSearch.class_eval do
  def format_any_value_team_tasks_field(_tt)
    { exists: { field: "task_responses.value" } }
  end

  def format_numeric_range_team_tasks_field(tt)
    format_numeric_range_condition('task_responses.numeric_value', tt['range'])
  end

  def format_date_range_team_tasks_field(tt)
    timezone = tt['range'].delete(:timezone) || @context_timezone
    values = tt['range']
    range = format_times_search_range_filter(values, timezone)
    range.nil? ? {} : ProjectMedia.send('field_search_query_type_range', 'task_responses.date_value', range, timezone)
  end

  def format_choice_team_tasks_field(tt)
    if tt['response'].is_a?(Array)
      { terms: { 'task_responses.value.raw': tt['response'] } }
    else
      { term: { 'task_responses.value.raw': tt['response'] } }
    end
  end
end
