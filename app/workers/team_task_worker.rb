class TeamTaskWorker
  include Sidekiq::Worker

  def perform(action, id, author, options = {}, projects = {})
    if action == 'update'
      team_task = TeamTask.find_by_id(id)
      options = YAML::load(options)
      projects = YAML::load(projects)
      author = YAML::load(author)
      unless team_task.nil?
        Team.current = team_task.team
        User.current = author
        team_task.update_teamwide_tasks_bg(options, projects)
        Team.current = User.current = nil
      end
    elsif action == 'destroy'
      TeamTask.destroy_teamwide_tasks_bg(id)
    end
  end

end
