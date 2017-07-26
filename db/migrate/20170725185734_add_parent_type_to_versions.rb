class AddParentTypeToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :associated_type, :string
    add_index :versions, :associated_type
  end
end
