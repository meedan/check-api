class TeamTask < ApplicationRecord
  include ErrorNotification

  attr_accessor :keep_completed_tasks

  before_validation :set_order, on: :create

  validates_presence_of :label, :team_id, :fieldset
  validates :task_type, included: { values: Task.task_types }
  validate :fieldset_exists_in_team

  serialize :options, Array
  serialize :project_ids, Array
  serialize :mapping

  belongs_to :team, optional: true

  after_create :add_teamwide_tasks
  after_update :update_teamwide_tasks
  after_commit :delete_teamwide_tasks, on: :destroy
  after_destroy :reorder

  def as_json(_options = {})
    super.merge({
      projects: self.project_ids,
      type: self.task_type
    }).with_indifferent_access
  end

  def json_options=(json)
    self.options = JSON.parse(json) unless json.blank?
  end

  def json_project_ids=(json)
    self.project_ids = JSON.parse(json) unless json.blank?
  end

  def projects=(ids)
    self.project_ids = ids
  end

  def projects
    self.project_ids
  end

  def type
    self.task_type
  end

  def type=(value)
    self.task_type = value
  end

  def add_teamwide_tasks_bg(_options, _projects, _keep_completed_tasks)
    # add metadata to items or sources based on associated_type field
    if self.fieldset == 'metadata' && self.associated_type == 'Source'
      add_to_sources
    else
      # items related to added projects
      condition = self.project_ids.blank? ? { team_id: self.team_id } : { project_id: self.project_ids }
      handle_add_projects(condition)
    end
  end

  def update_teamwide_tasks_bg(options, projects, keep_completed_tasks)
    # get project medias for deleted projects
    handle_remove_projects(projects) unless projects.blank?
    # collect updated fields with new values
    columns = {}
    options.each do |k, _v|
      attribute = self.read_attribute(k)
      # type is called `task_type` on TeamTask and `type` on Task
      k = :type if k == :task_type
      columns[k] = attribute
    end
    unless columns.blank?
      update_tasks(columns, keep_completed_tasks)
    end
    # items related to added projects
    unless projects.blank?
      condition, excluded_ids = build_add_remove_project_condition('add', projects)
      handle_add_projects(condition, excluded_ids) unless condition.blank?
    end
  end

  def self.destroy_teamwide_tasks_bg(id, keep_completed_tasks)
    if keep_completed_tasks
      TeamTask.get_teamwide_tasks_zero_answers(id).find_each do |t|
        self.destory_project_media_task(t)
      end
    else
      Task.where(annotation_type: 'task', annotated_type: ['ProjectMedia', 'Source'])
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id).find_each do |t|
        self.destory_project_media_task(t)
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
    task1.update_column(:order, task2_order)
    task2.update_column(:order, task1_order)
    task2_order
  end

  private

  def add_teamwide_tasks
    Rails.cache.delete("list_columns:team:#{self.team_id}")
    projects = { new: self.project_ids }
    TeamTaskWorker.perform_in(1.second, 'add', self.id, YAML::dump(User.current), YAML::dump({}), YAML::dump(projects))
  end

  def update_teamwide_tasks
    Rails.cache.delete("list_columns:team:#{self.team_id}")
    options = {
      label: self.saved_change_to_label?,
      description: self.saved_change_to_description?,
      task_type: self.saved_change_to_task_type?,
      options: self.saved_change_to_options?
    }
    options.delete_if{|_k, v| v == false || v.nil?}
    projects = {}
    if self.saved_change_to_project_ids?
      projects = {
        old: self.project_ids_before_last_save,
        new: self.project_ids,
      }
    end
    self.keep_completed_tasks = self.keep_completed_tasks.nil? ? true : self.keep_completed_tasks
    TeamTaskWorker.perform_in(1.second, 'update', self.id, YAML::dump(User.current), YAML::dump(options), YAML::dump(projects), self.keep_completed_tasks) unless options.blank? && projects.blank?
  end

  def delete_teamwide_tasks
    Rails.cache.delete("list_columns:team:#{self.team_id}")
    self.keep_completed_tasks = self.keep_completed_tasks.nil? ? false : self.keep_completed_tasks
    TeamTaskWorker.perform_in(1.second, 'destroy', self.id, YAML::dump(User.current), YAML::dump({}), YAML::dump({}), self.keep_completed_tasks)
  end

  def add_to_sources
    Source.where(team_id: self.team_id).find_each do |s|
      begin
        s.create_auto_tasks(nil, [self])
      rescue StandardError => e
        team_task_notification_error(e, s)
      end
    end
  end

  def handle_remove_projects(projects)
    condition, excluded_ids = build_add_remove_project_condition('remove', projects)
    unless condition.blank?
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia')
      .joins("INNER JOIN project_medias pm ON annotations.annotated_id = pm.id")
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
      .where(condition)
      .where("pm.project_id NOT IN (?) OR pm.project_id IS NULL", excluded_ids)
      .find_each { |t| t.destroy }
    end
  end

  def build_add_remove_project_condition(action, projects)
    # This method to build conditions based on add/remove action
    if_key, else_key = action == 'add' ? [:new, :old] : [:old, :new]
    prefix = action == 'add' ? '' : 'pm.'
    condition = {}
    excluded_ids = [0]
    if projects[if_key].blank?
      condition = { "#{prefix}team_id": self.team_id }
      excluded_ids = projects[else_key]
    elsif !projects[else_key].blank?
      condition = { "#{prefix}project_id": projects[if_key] }
    end
    [condition, excluded_ids]
  end

  def update_tasks(columns, keep_completed_tasks)
    columns = columns.except(:type, :options) if get_teamwide_tasks_with_answers.any?
    # update tasks with zero answer
    update_tasks_with_zero_answer(columns)
    # handle tasks with answers
    update_tasks_with_answer(columns) unless keep_completed_tasks
  end

  def update_tasks_with_zero_answer(columns)
    TeamTask.get_teamwide_tasks_zero_answers(self.id).find_each do |t|
      t.skip_check_ability = true
      t.update(columns)
    end
  end

  def update_tasks_with_answer(columns)
    get_teamwide_tasks_with_answers.find_each do |t|
      t.skip_check_ability = true
      t.update(columns)
    end
  end

  def handle_add_projects(condition, excluded_ids = [0])
    # bypass trashed items
    condition.merge!({ archived: CheckArchivedFlags::FlagCodes::NONE })
    ProjectMedia.where(condition)
    .where("project_medias.project_id NOT IN (?) OR project_medias.project_id IS NULL", excluded_ids)
    .joins("LEFT JOIN annotations a ON a.annotation_type = 'task' AND a.annotated_type = 'ProjectMedia'
      AND a.annotated_id = project_medias.id
      AND task_team_task_id(a.annotation_type, a.data) = #{self.id}")
    .where("a.id" => nil).order(id: :desc).distinct.find_each do |pm|
      begin
        pm.create_auto_tasks(nil, [self])
      rescue StandardError => e
        team_task_notification_error(e, pm)
      end
    end
  end

  def self.get_teamwide_tasks_zero_answers(id)
    Task.where('annotations.annotation_type' => 'task')
    .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id)
    .joins("LEFT JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
    .where('responses.id' => nil)
  end

  def get_teamwide_tasks_with_answers
    Task.where('annotations.annotation_type' => 'task')
    .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
    .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
      AND responses.annotated_type = 'Task'
      AND responses.annotated_id = annotations.id"
      )
  end

  def self.destory_project_media_task(t)
    t.skip_check_ability = true
    t.destroy
  end

  def fieldset_exists_in_team
    errors.add(:base, I18n.t(:fieldset_not_defined_by_team)) unless self.team&.get_fieldsets.to_a.collect{ |f| f['identifier'] }.include?(self.fieldset)
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
    TeamTask.notify_error(e, { team_task_id: self.id, item_type: obj.class.name, item_id: obj.id }, RequestStore[:request] )
    Rails.logger.error "[Team Task] Could not add team task [#{self.id}] to a #{obj.class.name} [#{obj.id}]: #{e.message} #{e.backtrace.join("\n")}"
  end
end

Team.class_eval do
  def ordered_team_tasks(fieldset)
    TeamTask.where(team_id: self.id, fieldset: fieldset).order(order: :asc, id: :asc)
  end
end
