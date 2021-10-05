class AddLastSeenToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :last_seen, :integer
    add_index :project_medias, :last_seen
  end
end
