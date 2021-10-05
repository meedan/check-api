class ConvertTaskStatusesToWorkflow < ActiveRecord::Migration[4.2]
  def change
    Annotation.reset_column_information

    RequestStore.store[:skip_notifications] = true

    annotations = []
    
    puts 'Migrating task statuses...'
    puts 'Loading annotations...'

    Task.where(annotation_type: 'task').find_each do |t|
      annotation = Dynamic.new(annotation_type: 'task_status', annotated_type: 'Task', annotated_id: t.id)
      annotation.fields.build(field_name: 'task_status_status', value: t.data[:status].downcase, annotation_type: 'task_status', field_type: 'select')
      annotations << annotation
    end

    puts 'Bulk-inserting annotations...'

    Dynamic.import annotations, recursive: true, validate: false

    puts 'Done!'
    
    RequestStore.store[:skip_notifications] = false
  end
end
