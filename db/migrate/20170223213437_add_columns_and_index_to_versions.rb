class AddColumnsAndIndexToVersions < ActiveRecord::Migration[4.2]
  def change
    # Add column
    add_column :versions, :meta, :text
    add_column :versions, :associated_id, :integer
    add_column :versions, :associated_type, :string
    add_column :versions, :event_type, :string
    add_column :versions, :team_id, :integer
    add_column(:versions, :object_after, :text) unless PaperTrail::Version.column_names.include?('object_after')
    change_column :versions, :item_id, :string
    # Add index
    add_index :versions, :associated_id
    add_index :versions, :event_type
    add_index :versions, :team_id
    add_index :versions, [:item_type, :item_id, :whodunnit]
    PaperTrail::Version.reset_column_information
  end
end
