class AddMetaToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :meta, :text
  end
end
