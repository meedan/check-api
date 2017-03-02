class AddEventTypeToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :event_type, :string
  end
end
