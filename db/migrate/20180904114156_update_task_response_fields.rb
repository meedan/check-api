class UpdateTaskResponseFields < ActiveRecord::Migration
  def change
    DynamicAnnotation::FieldInstance.where("name LIKE 'response_%'").update_all(optional: true)
  end
end
