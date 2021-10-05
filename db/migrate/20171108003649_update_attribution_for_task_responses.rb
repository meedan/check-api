class UpdateAttributionForTaskResponses < ActiveRecord::Migration[4.2]
  def change
    Annotation.reset_column_information
    Dynamic.reset_column_information
    Dynamic.where("annotation_type LIKE 'task_response%'").find_each do |task_response|
      user_ids = []
      task_response.versions.each do |version|
        user_ids << version.whodunnit.to_i unless version.whodunnit.nil?
      end
      task_response.update_column :attribution, user_ids.uniq.join(',')
    end
  end
end
