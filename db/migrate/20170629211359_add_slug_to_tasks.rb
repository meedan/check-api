class AddSlugToTasks < ActiveRecord::Migration
  def change
    Task.where(annotation_type: 'task').find_each do |task|
      task.slug = Task.slug(task.label)
      task.update_columns(data: task.data)
    end
  end
end
