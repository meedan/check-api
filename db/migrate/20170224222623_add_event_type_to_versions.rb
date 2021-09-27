class AddEventTypeToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :event_type, :string
  end
end
