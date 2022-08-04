class TeamTaskWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :tsqueue

  def perform(action, id, author, options = YAML::dump({}), projects = YAML::dump({}), keep_completed_tasks = false, diff = {})
    RequestStore.store[:skip_notifications] = true
    user_current = User.current
    team_current = Team.current
    options = YAML::load(options)
    author = YAML::load(author)
    User.current = author
    if action == 'update' || action == 'add'
      team_task = TeamTask.find_by_id(id)
      unless team_task.nil?
        Team.current = team_task.team
        method = "#{action}_teamwide_tasks_bg"
        team_task.send(method, options) if team_task.respond_to?(method)
      end
    elsif action == 'destroy'
      RequestStore.store[:skip_check_ability] = true
      TeamTask.destroy_teamwide_tasks_bg(id, keep_completed_tasks)
      RequestStore.store[:skip_check_ability] = true
    end
    Team.current = team_current
    User.current = user_current
    RequestStore.store[:skip_notifications] = false
  end
end
