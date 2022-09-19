class TeamTaskWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :tsqueue

  def perform(action, id, author, fields = YAML::dump({}), keep_completed_tasks = false, options_diff = {})
    RequestStore.store[:skip_notifications] = true
    user_current = User.current
    team_current = Team.current
    fields = YAML::load(fields)
    author = YAML::load(author)
    User.current = author
    if action == 'update' || action == 'add'
      team_task = TeamTask.find_by_id(id)
      return if team_task.nil?
      Team.current = team_task.team
      action == 'update' ?
        team_task.update_teamwide_tasks_bg(fields, options_diff) : team_task.add_teamwide_tasks_bg
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
