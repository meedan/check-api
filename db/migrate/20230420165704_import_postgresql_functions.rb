class ImportPostgresqlFunctions < ActiveRecord::Migration[6.0]
  def change
    create_function :task_fieldset
    create_function :task_team_task_id
    create_function :dynamic_annotation_fields_value
    create_function :version_field_name
    create_function :version_annotation_type
  end
end
