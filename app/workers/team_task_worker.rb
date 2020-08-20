class TeamTaskWorker
  include Sidekiq::Worker

  def perform(action, id, author, options = YAML::dump({}), projects = YAML::dump({}), keep_completed_tasks = false)
    user_current = User.current
    team_current = Team.current
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
    elsif action == 'remove_from'
      handle_remove_from(id, options)
    elsif action == 'destroy'
      RequestStore.store[:skip_check_ability] = true
      TeamTask.destroy_teamwide_tasks_bg(id, keep_completed_tasks)
      RequestStore.store[:skip_check_ability] = true
    end
    Team.current = team_current
    User.current = user_current
  end

  private

  def handle_remove_from(pid, options)
    pm = ProjectMedia.find_by_id(options[:project_media_id])
    ProjectMediaProject.remove_related_team_tasks_bg(pid, pm.id) unless pm.nil?
  end
end
