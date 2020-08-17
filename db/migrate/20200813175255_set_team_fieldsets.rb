class SetTeamFieldsets < ActiveRecord::Migration
  def change
    started = Time.now.to_i
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
    count = Task.where(annotation_type: 'task').count
    if count > 0
      # remove annotation indexes (to make migration faster)
      remove_index :annotations, name: "index_annotations_on_annotation_type"
      remove_index :annotations, name: "index_annotations_on_annotated_type_and_annotated_id"
      remove_index :annotations, name: "index_annotation_type_order"
      Task.where(annotation_type: 'task').find_in_batches(:batch_size => 10000) do |tasks|
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
      # re-add annotation indexes
      add_index :annotations, :annotation_type
      add_index :annotations, [:annotated_type, :annotated_id]
      add_index :annotations, :annotation_type, name: 'index_annotation_type_order', order: { name: :varchar_pattern_ops }
    end
    RequestStore.store[:skip_notifications] = false
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done. set Fieldset for #{count} tasks in #{minutes} minutes."
  end
end
