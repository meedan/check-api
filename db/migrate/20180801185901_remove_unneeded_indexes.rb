class RemoveUnneededIndexes < ActiveRecord::Migration
  def change
    remove_index :account_sources, name: "index_account_sources_on_account_id"
    remove_index :annotations, name: "index_annotations_on_annotated_type"
    remove_index :claim_sources, name: "index_claim_sources_on_media_id"
    remove_index :project_medias, name: "index_project_medias_on_project_id"
    remove_index :project_sources, name: "index_project_sources_on_project_id"
    remove_index :relationships, name: "index_relationships_on_source_id"
    remove_index :relationships, name: "index_relationships_on_source_id_and_target_id"
    remove_index :team_users, name: "index_team_users_on_team_id"
    remove_index :team_users, name: "index_team_users_on_user_id"
    remove_index :versions, name: "index_versions_on_item_type"
  end
end
