class TeamTaskWorker
  include Sidekiq::Worker

  def perform(action, id, author, options = YAML::dump({}), projects = YAML::dump({}), keep_completed_tasks = false)
    options = YAML::load(options)
    projects = YAML::load(projects)
    author = YAML::load(author)
    User.current = author
    if action == 'update' || action == 'add'
      team_task = TeamTask.find_by_id(id)
      unless team_task.nil?
        Team.current = team_task.team
        fun = "#{action}_teamwide_tasks_bg"
        team_task.send(fun, options, projects, keep_completed_tasks) if team_task.respond_to?(fun)
      end
    elsif action == 'add_or_move'
      project = Project.find_by_id(id)
      unless project.nil?
        project_media = options[:model]
        Team.current = project.team
        project_media.add_destination_team_tasks_bg(project)
      end
    elsif action == 'destroy'
      TeamTask.destroy_teamwide_tasks_bg(id, keep_completed_tasks)
    end
    Team.current = User.current = nil
  end

end
