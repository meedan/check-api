namespace :check do
	# bundle exec rake check:migrate_task_answers
	# relate task answers to the task itself
  desc "Migrate task answers so they related to the task itself"
  task migrate_task_answers: :environment do
    RequestStore.store[:skip_notifications] = true
    field_names = ['task_free_text', 'task_yes_no', 'task_single_choice', 'task_multiple_choice', 'task_datetime']
    total = DynamicAnnotation::Field.where(field_name: field_names).count
    i = 0
    DynamicAnnotation::Field.where(field_name: field_names).find_each do |task_ref|
      i += 1
      tid = task_ref.value.to_i
      msg = "Success"
      if tid == 0
        msg = "Invalid task id '#{task_ref.value}'"
      else
        task = Task.where(id: tid).last
        if task.nil?
          msg = "Could not find task with id '#{tid}'"
        else
          annotation = task_ref.annotation
          if annotation.nil?
            msg = "Could not find annotation"
          else
            annotation.update_columns(annotated_type: 'Task', annotated_id: tid)
          end
        end
      end
      task_ref.delete
      puts "Migrating task answer #{i}/#{total}: #{msg}"
    end
    RequestStore.store[:skip_notifications] = false
  end
end
