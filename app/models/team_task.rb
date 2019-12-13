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
    # get project medias for deleted projects
    pm_ids = handle_removed_projects(projects[:removed]) unless projects[:removed].blank?
    # update tasks with zero answer
    update_tasks_with_zero_answer(options, pm_ids)
    # handle tasks with answers
    update_tasks_with_answer if options[:required]
    # items related to added projects
    handle_added_projects(projects[:added]) unless projects[:added].blank?
  end

  def self.destroy_teamwide_tasks_bg(id)
    TeamTask.get_teamwide_tasks_zero_answers(id).find_each do |t|
      t.destroy
    end
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

  def handle_removed_projects(projects)
    ProjectMedia.where(project: projects).map(&:id)
  end

  def update_tasks_with_zero_answer(options, pm_ids)
    # collect updated fields with new values
    colums = {}
    options.each do |k, _v|
      colums[k] = self.read_attribute(k)
    end
    pm_ids ||= []
    excluded_ids = []
    # working with required options (F => T)
    if self.required? && options[:required]
      # Get tasks that are unresolved AND their item is at a terminal status
      colums.delete_if{|k, _v| k == :required}
      get_teamwide_tasks_unresolved_with_terminal.find_each do |t|
        excluded_ids << t.id
        if pm_ids.include?(t.annotated_id)
          t.destroy
        elsif !colums.blank?
          t.update(colums)
        end
      end
    end
    colums[:required] = self.read_attribute(:required) if options[:required]
    # get tasks with zero ansers expect unresolved and their item in terminal status
    # and apply updates for (title/description/options) only
    TeamTask.get_teamwide_tasks_zero_answers(self.id, excluded_ids).find_each do |t|
      if pm_ids.include?(t.annotated_id)
        t.destroy
      elsif !colums.blank?
        t.update(colums)
      end
    end
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

  def handle_added_projects(projects)
    excluded_ids = []
    if self.required?
      # Get items in termainl status
      team_statuses = team.final_media_statuses.map(&:to_yaml)
      excluded_ids =
      ProjectMedia.where(project: projects)
      .joins("INNER JOIN annotations s2 ON s2.annotation_type = 'verification_status'
        AND s2.annotated_id = project_medias.id")
      .joins(ActiveRecord::Base.send(:sanitize_sql_array,
        ["INNER JOIN dynamic_annotation_fields f2 ON f2.field_name = 'verification_status_status'
          AND f2.value IN (?)
          AND f2.annotation_id = s2.id",
          team_statuses])
        ).map(&:id)
    end
    ProjectMedia.where(project: projects).where.not(id: excluded_ids).find_each do |pm|
      pm.create_auto_tasks
    end
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
    team_statuses = team.final_media_statuses.map(&:to_yaml)
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
end
