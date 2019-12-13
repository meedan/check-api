class TeamTaskWorker
  include Sidekiq::Worker

  def perform(action, id, options = {}, projects = {})
    if action == 'update'
      team_task = TeamTask.find_by_id(id)
      options = YAML::load(options)
      projects = YAML::load(projects)
      team_task.update_teamwide_tasks_bg(options, projects) unless team_task.nil?
    elsif action == 'destroy'
      TeamTask.destroy_teamwide_tasks_bg(id)
    end
  end

end
