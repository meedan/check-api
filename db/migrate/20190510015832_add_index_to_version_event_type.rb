class AddIndexToVersionEventType < ActiveRecord::Migration[4.2]
  def change
    add_index :versions, :event_type
  end
end
