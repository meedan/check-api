class TeamTask < ActiveRecord::Base
  validates_presence_of :label, :team_id
  validates :task_type, included: { values: Task.task_types }

  serialize :options, Array
  serialize :project_ids, Array

  belongs_to :team

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
end
