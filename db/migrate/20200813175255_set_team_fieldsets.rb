class SetTeamFieldsets < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    RequestStore.store[:skip_notifications] = true
    RequestStore.store[:skip_rules] = true
    fieldsets = [
      {
        identifier: 'tasks',
        singular: 'task',
        plural: 'tasks'
      }.with_indifferent_access,
      {
        identifier: 'metadata',
        singular: 'metadata',
        plural: 'metadata'
      }.with_indifferent_access
    ]
    # Set fieldsets setting to be the default for all teams
    Team.find_each do |t|
      print '.'
      settings = t.settings || {}
      settings[:fieldsets] = fieldsets
      t.update_column(:settings, settings)
    end
    puts 'Updated Teams settings'
    # Set fieldset = "tasks" for all TeamTasks
    TeamTask.update_all(fieldset: 'tasks')
    puts 'Updated TeamTasks'
    # Set fieldset: "tasks" for all Tasks
    failed_tasks = []
    Task.where(annotation_type: 'task').find_in_batches(:batch_size => 5000) do |tasks|
      new_tasks = []
      tasks.each do |t|
        print "."
        t.data["fieldset"] = 'tasks'
        new_tasks <<  t
      end
      # Import new tasks with old ids to keep versions
      imported = Task.import(new_tasks, recursive: false, validate: false, on_duplicate_key_update: [:data])
      # log failed instances
      failed_tasks.concat imported.failed_instances unless imported.failed_instances.blank?
    end
    RequestStore.store[:skip_notifications] = false
    RequestStore.store[:skip_rules] = false
    puts "Failed to update #{failed_tasks.count} tasks #{failed_tasks.inspect}" unless failed_tasks.blank?
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done. set Fieldset for tasks in #{minutes} minutes."
  end
end
