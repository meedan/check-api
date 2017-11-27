class AddLockVersionToSourcesAndDynamic < ActiveRecord::Migration
  def change
    add_column :annotations, :lock_version, :integer, default: 0, null: false
    add_column :sources, :lock_version, :integer, default: 0, null: false
  end
end
