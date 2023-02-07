class RemoveUnusedIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :versions, name: "index_versions_on_item_type_and_item_id"
    remove_index :versions, name: "index_versions_on_associated_type"
    remove_index :versions, name: "index_versions_on_item_id"
    remove_index :dynamic_annotation_fields, name: "index_dynamic_annotation_fields_on_field_name"
    remove_index :dynamic_annotation_fields, name: "index_dynamic_annotation_fields_on_annotation_type"
    remove_index :medias, name: "index_medias_on_account_id"
    remove_index :medias, name: "index_medias_on_user_id"
    remove_index :sources, name: "index_sources_on_archived"
    remove_index :sources, name: "index_sources_on_team_id"
    remove_index :sources, name: "index_sources_on_user_id"
    remove_index :users, name: "index_users_on_source_id"
    remove_index :contacts, name: "index_contacts_on_team_id"
  end
end
