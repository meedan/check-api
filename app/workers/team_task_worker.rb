class TeamTaskWorker
  include Sidekiq::Worker

  def perform(id, options, projects)
  	options = YAML::load(options)
  	projects = YAML::load(projects)
    team_task = TeamTask.find_by_id(id)
    team_task.update_teamwide_tasks_bg(options, projects) unless team_task.nil?
  end

end
