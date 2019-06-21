class AddIndexToVersionEventType < ActiveRecord::Migration
  def change
    add_index :versions, :event_type
  end
end
