class AddArchivedFlag < ActiveRecord::Migration[4.2]
  def change
    add_column :sources, :archived, :integer, default: 0
    add_index :sources, :archived
  end
end
