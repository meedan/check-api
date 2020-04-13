class TeamTask < ActiveRecord::Base
  include ErrorNotification

  attr_accessor :skip_update_media_status, :keep_resolved_tasks

  validates_presence_of :label, :team_id
  validates :task_type, included: { values: Task.task_types }

  serialize :options, Array
  serialize :project_ids, Array
  serialize :mapping

  belongs_to :team

  after_create :add_teamwide_tasks
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

  def add_teamwide_tasks_bg(_options, _projects, _keep_resolved_tasks)
    # items related to added projects
    condition = self.project_ids.blank? ? { team_id: self.team_id } : { project_id: self.project_ids }
    handle_add_projects(condition)
  end

  def update_teamwide_tasks_bg(options, projects, keep_resolved_tasks)
    # get project medias for deleted projects
    handle_remove_projects(projects) unless projects.blank?
    # update tasks with zero answer
    update_tasks_with_zero_answer(options, keep_resolved_tasks)
    # handle tasks with answers
    update_tasks_with_answer if options[:required]
    # items related to added projects
    unless projects.blank?
      condition, excluded_ids = build_add_remove_project_condition('add', projects)
      handle_add_projects(condition, excluded_ids) unless condition.blank?
    end
  end

  def self.destroy_teamwide_tasks_bg(id, keep_resolved_tasks)
    if keep_resolved_tasks
      Task.where('annotations.annotation_type' => 'task')
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id)
      .joins("INNER JOIN annotations s ON s.annotation_type = 'task_status' AND s.annotated_id = annotations.id")
      .joins("INNER JOIN dynamic_annotation_fields f ON f.field_name = 'task_status_status'
        AND f.value LIKE '%unresolved%'
        AND f.annotation_id = s.id").find_each do |t|
        self.destory_project_media_task(t)
      end
    else
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia')
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', id).find_each do |t|
        self.destory_project_media_task(t)
      end
    end
  end

  def handle_added_tasks_to_terminal_status_item(condition)
    # Get items with terminal status
    terminal_ids = get_items_in_terminal_status(condition)
    unless terminal_ids.blank?
      # resolve tasks that added to terminal status items
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia' , annotated_id: terminal_ids)
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
      .find_each do |t|
        t.status = 'resolved'
        t.skip_check_ability = true
        t.save!
      end
    end
  end

  private

  def add_teamwide_tasks
    projects = { new: self.project_ids }
    TeamTaskWorker.perform_in(1.second, 'add', self.id, YAML::dump(User.current), YAML::dump({}), YAML::dump(projects))
  end

  def update_teamwide_tasks
    options = {
      label: self.label_changed?,
      description: self.description_changed?,
      required: self.required_changed?,
      options: self.options_changed?
    }
    options.delete_if{|_k, v| v == false || v.nil?}
    projects = {}
    if self.project_ids_changed?
      projects = {
        old: self.project_ids_was,
        new: self.project_ids,
      }
    end
    self.keep_resolved_tasks = self.keep_resolved_tasks.nil? ? true : self.keep_resolved_tasks
    TeamTaskWorker.perform_in(1.second, 'update', self.id, YAML::dump(User.current), YAML::dump(options), YAML::dump(projects), self.keep_resolved_tasks) unless options.blank? && projects.blank?
  end

  def delete_teamwide_tasks
    self.keep_resolved_tasks = self.keep_resolved_tasks.nil? ? false : self.keep_resolved_tasks
    TeamTaskWorker.perform_in(1.second, 'destroy', self.id, YAML::dump(User.current), YAML::dump({}), YAML::dump({}), self.keep_resolved_tasks)
  end

  def handle_remove_projects(projects)
    condition, excluded_ids, terminal_ids = build_add_remove_project_condition('remove', projects)
    unless condition.blank?
      Task.where(annotation_type: 'task', annotated_type: 'ProjectMedia')
      .joins("INNER JOIN project_medias pm ON annotations.annotated_id = pm.id")
      .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
      .where(condition)
      .where.not(terminal_ids)
      .where("pm.project_id NOT IN (?) OR pm.project_id IS NULL", excluded_ids)
      .find_each { |t| t.destroy }
    end
  end

  def build_add_remove_project_condition(action, projects)
    # This method to build conditions based on add/remove action
    # and take in consideration a terminal status items on remove action
    if_key, else_key = action == 'add' ? [:new, :old] : [:old, :new]
    prefix = action == 'add' ? '' : 'pm.'
    condition = {}
    excluded_ids = [0]
    terminal_ids = {id: [0]}
    if projects[if_key].blank?
      condition = { "#{prefix}team_id": self.team_id }
      excluded_ids = projects[else_key]
      if action == 'remove'
        ids = get_items_in_terminal_status({ team_id: self.team_id })
        terminal_ids = {"#{prefix}id": ids}
      end
    elsif !projects[else_key].blank?
      condition = { "#{prefix}project_id": projects[if_key] }
      if action == 'remove'
        ids = get_items_in_terminal_status({ project_id: projects[if_key] })
        terminal_ids = {"#{prefix}id": ids}
      end
    end
    [condition, excluded_ids, terminal_ids]
  end

  def update_tasks_with_zero_answer(options, keep_resolved_tasks)
    # collect updated fields with new values
    colums = {}
    options.each do |k, _v|
      colums[k] = self.read_attribute(k)
    end
    excluded_ids = []
    # working with required options (F => T)
    if self.required? && options[:required]
      # Get tasks that are unresolved AND their item in a terminal status
      colums.delete_if{|k, _v| k == :required}
      get_teamwide_tasks_unresolved_with_terminal.find_each { |t| excluded_ids << t.id ; t.update(colums) unless colums.blank? }
    end
    update_resolved_tasks(colums) unless keep_resolved_tasks || colums.blank?
    colums[:required] = self.read_attribute(:required) if options[:required]
    # get tasks with zero ansers expect unresolved and their item in terminal status
    # and apply updates for (title/description/options) only
    TeamTask.get_teamwide_tasks_zero_answers(self.id, excluded_ids).find_each do |t|
      t.update(colums)
    end unless colums.blank?
  end

  def update_tasks_with_answer
    excluded_ids = []
    if self.required?
      excluded_ids = get_teamwide_tasks_unresolved_with_terminal.map(&:id)
    end
    get_teamwide_tasks_with_answers.find_each do |t|
      t.update({required: self.required?}) unless excluded_ids.include?(t.id)
    end
  end

  def update_resolved_tasks(colums)
    Task.where('annotations.annotation_type' => 'task')
    .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
    .joins("INNER JOIN annotations s ON s.annotation_type = 'task_status' AND s.annotated_id = annotations.id")
    .joins("INNER JOIN dynamic_annotation_fields f ON f.field_name = 'task_status_status'
      AND f.value LIKE '%resolved%'
      AND f.annotation_id = s.id").find_each do |t|
      t.update(colums)
    end
  end

  def handle_add_projects(condition, excluded_ids = [0])
    ProjectMedia.where(condition)
    .where("project_id NOT IN (?) OR project_id IS NULL", excluded_ids)
    .joins("LEFT JOIN annotations a ON a.annotation_type = 'task' AND a.annotated_type = 'ProjectMedia'
      AND a.annotated_id = project_medias.id
      AND task_team_task_id(a.annotation_type, a.data) = #{self.id}")
    .where("a.id" => nil).find_each do |pm|
      begin
        self.skip_update_media_status = true if self.required?
        pm.create_auto_tasks([self])
      rescue StandardError => e
        TeamTask.notify_error(e, { team_task_id: self.id, project_media_id: pm.id }, RequestStore[:request] )
        Rails.logger.error "[Team Task] Could not add team task [#{self.id}] to a media [#{pm.id}]: #{e.message} #{e.backtrace.join("\n")}"
      end
    end
    handle_added_tasks_to_terminal_status_item(condition) if self.required?
  end

  def self.get_teamwide_tasks_zero_answers(id, excluded_ids = [])
    Task.where('annotations.annotation_type' => 'task')
    .where.not(id: excluded_ids)
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

  def get_teamwide_tasks_unresolved_with_terminal
    team_statuses = self.team.final_media_statuses.map(&:to_yaml)
    Task.where('annotations.annotation_type' => 'task')
    .where('task_team_task_id(annotations.annotation_type, annotations.data) = ?', self.id)
    .joins("INNER JOIN annotations s ON s.annotation_type = 'task_status' AND s.annotated_id = annotations.id")
    .joins("INNER JOIN dynamic_annotation_fields f ON f.field_name = 'task_status_status'
      AND f.value LIKE '%unresolved%'
      AND f.annotation_id = s.id")
    .joins("INNER JOIN project_medias pm ON annotations.annotated_type = 'ProjectMedia'
      AND annotations.annotated_id = pm.id")
    .joins("INNER JOIN annotations s2 ON s2.annotation_type = 'verification_status'
      AND s2.annotated_id = pm.id")
    .joins(ActiveRecord::Base.send(:sanitize_sql_array,
      ["INNER JOIN dynamic_annotation_fields f2 ON f2.field_name = 'verification_status_status'
        AND f2.value IN (?)
        AND f2.annotation_id = s2.id",
        team_statuses]))
  end

  def get_items_in_terminal_status(condition)
    team_statuses = self.team.final_media_statuses.map(&:to_yaml)
    ProjectMedia.where(condition)
    .joins("INNER JOIN annotations s2 ON s2.annotation_type = 'verification_status'
      AND s2.annotated_id = project_medias.id")
    .joins(ActiveRecord::Base.send(:sanitize_sql_array,
      ["INNER JOIN dynamic_annotation_fields f2 ON f2.field_name = 'verification_status_status'
        AND f2.value IN (?)
        AND f2.annotation_id = s2.id",
        team_statuses])
      ).map(&:id)
  end

  def self.destory_project_media_task(t)
    t.skip_check_ability = true
    t.destroy
  end
end
