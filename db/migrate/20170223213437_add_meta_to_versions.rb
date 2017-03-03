class AddMetaToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :meta, :text
  end
end
