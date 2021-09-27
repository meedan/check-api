require 'sample_data'
include SampleData

class ConvertImageUploadTasksToFileUpload < ActiveRecord::Migration[4.2]
  def change
    RequestStore.store[:skip_notifications] = true
    RequestStore.store[:skip_rules] = true
    RequestStore.store[:skip_clear_cache] = true
    file = DynamicAnnotation::FieldType.where(field_type: 'file').last || create_field_type(field_type: 'file', label: 'File')
    DynamicAnnotation::AnnotationType.where(annotation_type: 'task_response_image_upload').update_all(annotation_type: 'task_response_file_upload', label: 'Task Response File Upload')
    DynamicAnnotation::FieldInstance.where(name: 'response_image_upload').update_all(name: 'response_file_upload', field_type: 'file', annotation_type: 'task_response_file_upload')
    DynamicAnnotation::FieldInstance.where(name: 'suggestion_image_upload').update_all(name: 'suggestion_file_upload', annotation_type: 'task_response_file_upload')
    DynamicAnnotation::FieldInstance.where(name: 'review_image_upload').update_all(name: 'review_file_upload', annotation_type: 'task_response_file_upload')
    DynamicAnnotation::Field.where(field_name: 'response_image_upload').update_all(field_name: 'response_file_upload', annotation_type: 'task_response_file_upload', field_type: 'file')
    TeamTask.where(task_type: 'image_upload').update_all(task_type: 'file_upload')
    tasks = Task.where(annotation_type: 'task').where("data LIKE '%image_upload%'")
    n = tasks.count
    i = 0
    tasks.find_each do |task|
      i += 1
      print "#{i}/#{n}) Updating task #{task.id}... "
      if task.type == 'image_upload'
        begin
          task.type = 'file_upload'
          task.save!
          puts "Saved!"
        rescue StandardError => e
          puts "Error! Error message is: #{e.message}"
        end
      end
    end
    RequestStore.store[:skip_notifications] = false
    RequestStore.store[:skip_rules] = false
    RequestStore.store[:skip_clear_cache] = false
  end
end
