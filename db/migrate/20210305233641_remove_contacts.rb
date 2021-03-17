class RemoveContacts < ActiveRecord::Migration
  def change
    drop_table(:contacts) if table_exists?(:contacts)
  end
end
