class ConvertTaskStatusesToWorkflow < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true
    
    Task.where(annotation_type: 'task').find_each do |t|
      t.send(:create_first_task_status)
      t.skip_check_ability = true
      t.skip_notifications = true
      t.skip_clear_cache = true
      begin
        t.save!
      rescue
        puts "Skipping task with id #{task.id}"
      end
    end
    
    RequestStore.store[:skip_notifications] = false
  end
end
