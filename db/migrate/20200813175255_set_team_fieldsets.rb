class SetTeamFieldsets < ActiveRecord::Migration
  def change
  	RequestStore.store[:skip_notifications] = true
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
  		settings = t.settings || {}
  		settings[:fieldsets] = fieldsets
  		t.update_column(:settings, settings)
  	end
  	# Set fieldset = "tasks" for all TeamTasks
  	TeamTask.update_all(fieldset: 'tasks')
  	# Set fieldset: "tasks" for all Tasks
  	Task.where(annotation_type: 'task').find_in_batches(:batch_size => 5000) do |tasks|
  		new_tasks = []
  		tasks.each do |t|
        print "."
        t.data["fieldset"] = 'tasks'
        new_tasks <<  t
      end
      # Delete existing task before import new tasks
      Task.where(id: tasks.map(&:id)).delete_all
      # Import new tasks with old ids to keep versions
      Task.import(new_tasks, recursive: false, validate: false)
  	end
  	RequestStore.store[:skip_notifications] = false
  end
end