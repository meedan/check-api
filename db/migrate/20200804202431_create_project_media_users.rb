class CreateProjectMediaUsers < ActiveRecord::Migration
  def change
    create_table :project_media_users do |t|
      t.references :project_media
      t.references :user
      t.boolean :read, default: false, null: false
    end
    add_index :project_media_users, :project_media_id
    add_index :project_media_users, :user_id
    add_index :project_media_users, [:project_media_id, :user_id], unique: true
  end
end
