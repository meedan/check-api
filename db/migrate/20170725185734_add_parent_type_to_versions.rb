class AddParentTypeToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :associated_type, :string
    add_index :versions, :associated_type
    # set associated_type for existing media
    PaperTrail::Version.where.not(project_media_id: nil).update_all(associated_type: 'ProjectMedia')
  end
end
