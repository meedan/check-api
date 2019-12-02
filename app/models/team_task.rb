class TeamTask < ActiveRecord::Base
  validates_presence_of :label, :team_id
  validates :task_type, included: { values: Task.task_types }

  serialize :options, Array
  serialize :project_ids, Array
  serialize :mapping

  belongs_to :team

  after_update :update_teamwide_tasks
  after_commit :delete_teamwide_tasks, on: :destroy

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

  def update_teamwide_tasks_bg(options, projects)
    all_tasks = TeamTask.get_teamwide_tasks(self.id)
    # tasks with zero answer
    t_zero_ans = all_tasks.select{|t| t.responses.count == 0}
    # Items related to removed projects
    t_zero_ans = handle_removed_projects(t_zero_ans,  projects[:removed]) unless projects[:removed].blank?
    # update tasks with zero answer
    update_tasks_with_zero_answer(t_zero_ans, options)
    # handle tasks with answers
    t_with_ans = all_tasks - t_zero_ans
    update_tasks_with_answer(t_with_ans) if options[:required]
    # items related to added projects
    handle_added_projects(projects[:added], t_with_ans) unless projects[:added].blank?
  end

  def self.destroy_teamwide_tasks_bg(id)
    all_tasks = TeamTask.get_teamwide_tasks(id)
    # tasks with zero answer
    t_zero_ans = all_tasks.select{|t| t.responses.count == 0}
    t_zero_ans.each{|t| t.destroy}
  end

  private

  def update_teamwide_tasks
    options = {
      label: self.label_changed?,
      description: self.description_changed?,
      required: self.required_changed?,
      options: self.options_changed?
    }
    options.delete_if{|_k, v| v == false || v.nil?}
    projects = {
      added: self.project_ids - self.project_ids_was,
      removed: self.project_ids_was - self.project_ids,
    }
    update_tasks = !options.blank? || projects.any?{|_k, v| !v.blank?}
    TeamTaskWorker.perform_in(1.second, 'update', self.id, YAML::dump(options), YAML::dump(projects)) if update_tasks
  end

  def delete_teamwide_tasks
    TeamTaskWorker.perform_in(1.second, 'destroy', self.id)
  end

  def self.get_teamwide_tasks(id)
    tasks = Annotation.where(annotation_type: 'task').select{|t| t.team_task_id == id}
    tasks = tasks.map(&:load)
    tasks
  end

  def handle_removed_projects(tasks, projects)
    pm_ids = ProjectMedia.where(project: projects).map(&:id)
    removed_items = tasks.select{|t| pm_ids.include?(t.annotated_id)}
    # updat tasks with zero answers list
    tasks = tasks - removed_items
    removed_items.each{|t| t.destroy}
    tasks
  end

  def update_tasks_with_zero_answer(tasks, options)
    # collect updated fields with new values
    colums = {}
    options.each do |k, _v|
      colums[k] = self.read_attribute(k)
    end
    # working with required options (F => T)
    if self.required? && options[:required]
      excluded_tasks = tasks.select{|t| t.status == 'unresolved' && t.annotated.is_finished? }
      t_without_terminal = tasks - excluded_tasks
      t_without_terminal.each{|t| t.update(colums)}
      colums.delete_if{|k, _v| k == :required}
      tasks = excluded_tasks
    end
    # other columns (title/description/options) than required field
    tasks.each do |t|
      t.update(colums)
    end unless colums.blank?
  end

  def update_tasks_with_answer(tasks)
    # remove tasks for terminal items
    tasks = tasks - tasks.select{|t| t.status == 'unresolved' && t.annotated.is_finished? } if self.required?
    tasks.each{|t| t.update({required: self.required})}
  end

  def handle_added_projects(projects, _tasks)
    project_medias = ProjectMedia.where(project: projects).to_a
    project_medias.delete_if {|pm| pm.is_finished? } if self.required?
    project_medias.each do |pm|
      pm.create_auto_tasks
    end
  end
end
