class CreateProjectMediaRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :project_media_requests do |t|
      t.references :project_media, null: false, foreign_key: true, index: true
      t.references :request, null: false, foreign_key: true, index: true
      t.timestamps
    end
    add_index :project_media_requests, [:request_id, :project_media_id], unique: true
  end
end
