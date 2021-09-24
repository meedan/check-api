class UpdateTaskResponseFields < ActiveRecord::Migration[4.2]
  def change
    DynamicAnnotation::FieldInstance.where("name LIKE 'response_%'").update_all(optional: true)
  end
end
