class RemoveContacts < ActiveRecord::Migration[4.2]
  def change
    drop_table(:contacts) if table_exists?(:contacts)
  end
end
