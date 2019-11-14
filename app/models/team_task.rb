class TeamTask < ActiveRecord::Base
  attr_accessor :t_changes

  validates_presence_of :label, :team_id
  validates :task_type, included: { values: Task.task_types }

  serialize :options, Array
  serialize :project_ids, Array
  serialize :mapping

  belongs_to :team

  before_update :set_task_changes
  after_update :update_teamwide_tasks

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

  private

  def set_task_changes
    self.t_changes = {
      label: self.label_changed?,
      description: self.description_changed?,
      required: self.required_changed?,
      options: self.options_changed?
    }
  end

  def update_teamwide_tasks
    tasks = Annotation.where(annotation_type: 'task').select{|t| t.team_task_id == self.id}
    tasks = tasks.map(&:load)
    tasks = tasks.select{|t| t.status == 'unresolved'}
    tasks.each do |t|
      t.label = self.label
      t.description = self.description
      t.options = self.options
      t.save!
    end
  end
end
