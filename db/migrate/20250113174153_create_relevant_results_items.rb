class CreateRelevantResultsItems < ActiveRecord::Migration[6.1]
  def change
    create_table :relevant_results_items do |t|
      t.references :user
      t.references :team
      t.integer :relevant_results_render_id
      t.string :user_action
      t.integer :query_media_parent_id
      t.integer :query_media_ids, array: true, default: []
      t.jsonb :similarity_settings, default: {}
      t.integer :matched_media_id
      t.integer :selected_count
      t.integer :display_rank
      t.references :article, polymorphic: true, null: false
      t.timestamps
    end
    add_index :relevant_results_items, [:article_type, :article_id]
  end
end
