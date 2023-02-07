class AddExtraIndexes < ActiveRecord::Migration[4.2]
  def change
    # User
    remove_index :users, name: "index_users_on_id"
    add_index :users, :login
    # DynamicAnnotation::Field
    remove_index :dynamic_annotation_fields, name: "index_dynamic_annotation_fields_on_annotation_id"
    remove_index :dynamic_annotation_fields, name: "index_dynamic_annotation_fields_on_field_name"
    add_index :dynamic_annotation_fields, [:annotation_id, :field_name]
    # TeamTask
    remove_index :team_tasks, name: "index_team_tasks_on_associated_type"
    remove_index :team_tasks, name: "index_team_tasks_on_fieldset"
    add_index :team_tasks, [:team_id, :fieldset, :associated_type]
    # TeamUser
    remove_index :team_users, name: "index_team_users_on_id"
    # Medias
    remove_index :medias, name: "index_medias_on_id"
  end
end
